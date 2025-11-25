import {genkit, z} from "genkit/beta";
import {onCallGenkit} from "firebase-functions/v2/https";
import {enableFirebaseTelemetry} from "@genkit-ai/firebase";
import {googleAI} from "@genkit-ai/google-genai";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {Document} from "genkit/retriever";
import {chunk} from "llm-chunk";
import {
  devLocalIndexerRef,
  devLocalVectorstore,
  devLocalRetrieverRef,
} from "@genkit-ai/dev-local-vectorstore";

// Interface for data stored in a Xenoprofile document (for bot personas)
interface XenoprofileFirestoreData {
  id: string;
  name: string;
  surname?: string | null; // Marked as optional in example usage
  earthage?: number | null; // Marked as optional in example usage
  gender: string;
  interests: string;
  likes: string;
  dislikes: string;
  imageUrl: string;
  biography: string;
  species: string;
  subspecies: string;
  location: string;
  lookingfor: string;
  orientation: string;
  redflags: string;
}

// Interface for data stored in a User's Character document
// Mirrors XenoprofileFirestoreData structure for consistency with persona data.
interface UserCharacterFirestoreData {
  id: string; // The characterId
  name: string;
  surname?: string | null;
  earthage?: number | null;
  gender: string;
  interests: string;
  likes: string;
  dislikes: string;
  imageUrl: string;
  biography: string;
  species: string;
  subspecies: string;
  location: string;
  lookingfor: string;
  orientation: string;
  redflags: string;
}

// Explicitly define allowed roles as per Genkit's expectation
interface GenkitMessagePart {
  text: string;
}

interface GenkitMessage {
  role: "user" | "model" | "system" | "tool";
  content: GenkitMessagePart[];
}

interface ChatMessage {
  role: "user" | "model";
  text: string;
  timestamp: FieldValue;
  senderId: string;
  receiverId: string;
  senderName: string;
}

enableFirebaseTelemetry();
const apiKey = defineSecret("GOOGLE_GENAI_API_KEY");

if (!admin.apps.length) {
  admin.initializeApp();
}

const xenoMemoryIndexName = "xenoMemory";

const ai = genkit({
  plugins: [
    googleAI(),
    devLocalVectorstore([
      {
        indexName: xenoMemoryIndexName,
        embedder: googleAI.embedder("gemini-embedding-001"),
      },
    ]),
  ],
});

const xenoMemoryIndexer = devLocalIndexerRef(xenoMemoryIndexName);
const xenoMemoryRetriever = devLocalRetrieverRef(xenoMemoryIndexName);

const ChatbotInputSchema = z.object({
  userId: z.string(),
  chatId: z.string(),
  xenoprofileId: z.string(),
  userMessage: z.string(),
  characterId: z.string(), // New: To identify the user's character persona
  characterName: z.string(), // New: To use as the sender's display name
});

const ChatbotOutputSchema = z.object({
  reply: z.string(),
});

const rollDice = ai.defineTool(
  {
    name: "rollDice",
    description: "Rolls a six-sided die",
    outputSchema: z.number().int().min(1).max(6),
  },
  async () => {
    return Math.floor(Math.random() * 6) + 1;
  }
);

interface ChunkingConfig {
  minLength: number;
  maxLength: number;
  splitter: "sentence" | "paragraph";
  overlap: number;
  delimiters: string;
}

const chunkingConfig: ChunkingConfig = {
  minLength: 100,
  maxLength: 500,
  splitter: "sentence",
  overlap: 50,
  delimiters: "",
};

const storeXenoMemory = ai.defineTool(
  {
    name: "storeXenoMemory",
    description:
      "Allows the xenoprofile bot to remember a specific detail about the " +
      "user's character. Use this when the user reveals a strong interest, " +
      "dislike, red flag, or a significant interaction.",
    inputSchema: z.object({
      xenoprofileId: z
        .string()
        .describe(
          "The ID of the xenoprofile (usually 'self' from the bot's " +
            "perspective)."
        ),
      characterId: z
        .string()
        .describe(
          "The ID of the user's character that triggered this memory."
        ),
      memoryTopic: z
        .enum(["interest", "dislike", "red_flag", "interaction"])
        .describe("The category of the memory."),
      memoryDetail: z
        .string()
        .describe(
          "The specific detail to remember about the user's character."
        ),
    }),
    outputSchema: z.object({
      status: z.string(),
      xenoprofileId: z.string(),
      characterId: z.string(),
      topic: z.string(),
    }),
  },
  async (input) => {
    const {xenoprofileId, characterId, memoryTopic, memoryDetail} = input;

    try {
      const chunks = await ai.run("chunk-memory-detail", async () =>
        chunk(memoryDetail, chunkingConfig)
      );

      const documents = chunks.map((text) => {
        return Document.fromText(text, {
          xenoprofileId,
          characterId,
          memoryTopic,
          timestamp: FieldValue.serverCimestamp(),
        });
      });

      await ai.index({
        indexer: xenoMemoryIndexer,
        documents,
      });

      return {
        status: "memory_saved",
        xenoprofileId,
        characterId,
        topic: memoryTopic,
      };
    } catch (error) {
      console.error(`Error storing xeno memory for ${xenoprofileId}:`, error);
      throw new Error(`Failed to store memory: ${(error as Error).message}`);
    }
  }
);

const retrieveXenoMemories = ai.defineTool(
  {
    name: "retrieveXenoMemories",
    description:
      "Retrieves relevant memories about a user's character for a specific " +
      "xenoprofile bot. Use this when you need to recall past interactions, " +
      "interests, dislikes, or red flags related to the user.",
    inputSchema: z.object({
      query: z
        .string()
        .describe("The query or topic for which to retrieve memories."),
      xenoprofileId: z.string().describe("The ID of the xenoprofile bot."),
      characterId: z
        .string()
        .optional()
        .describe(
          "Optional: The ID of the user's character to filter memories by."
        ),
      limit: z
        .number()
        .int()
        .min(1)
        .max(10)
        .optional()
        .describe(
          "Optional: The maximum number of memories to retrieve (default is 5)."
        ),
    }),
    outputSchema: z.object({
      memories: z.array(z.string()),
      xenoprofileId: z.string(),
      characterId: z.string().optional(),
    }),
  },
  async (input) => {
    const {query, xenoprofileId, characterId, limit = 5} = input;

    try {
      const options: {
        k: number;
        filter?: {xenoprofileId: string; characterId?: string};
      } = {k: limit};

      options.filter = {xenoprofileId};
      if (characterId) {
        options.filter.characterId = characterId;
      }

      const relevantMemories = await ai.retrieve({
        retriever: xenoMemoryRetriever,
        query: query,
        options: options,
      });

      const memoryDetails: string[] =
      relevantMemories.map((doc) => doc.content as string);

      return {memories: memoryDetails, xenoprofileId, characterId};
    } catch (error) {
      console.error(
        `Error retrieving xeno memories for ${xenoprofileId}:`,
        error
      );
      throw new Error(
        `Failed to retrieve memories: ${(error as Error).message}`
      );
    }
  }
);

/**
 * Fetches the persona details for the bot from a xenoprofile in Firestore.
 * @param {string} xenoprofileId The ID of the xenoprofile to fetch.
 */
async function getBotPersona(
  xenoprofileId: string
): Promise<{name: string; instructions: string}> {
  const firestore = getFirestore();

  try {
    const doc = await firestore
      .collection("xenoprofiles")
      .doc(xenoprofileId)
      .get();
    if (!doc.exists) {
      console.log(`Xenoprofile ID "${xenoprofileId}" not found.`);
      console.log("Using default bot persona.");
      return {name: "Default Bot", instructions: "Be helpful and concise."};
    }

    const data = doc.data() as XenoprofileFirestoreData | undefined;

    if (
      data &&
      typeof data.name === "string" &&
      typeof data.biography === "string"
    ) {
      let instructions = `You are ${data.name} ${data.surname || ""}. `;
      instructions += `Your biography states: "${data.biography}". `;
      if (data.species) {
        instructions += `You are a ${data.species}`;
        if (data.subspecies) instructions += ` (${data.subspecies})`;
        instructions += ". ";
      }
      if (data.earthage) {
        instructions += `You are ${data.earthage} Earth years old. `;
      }
      if (data.gender) instructions += `Your gender is ${data.gender}. `;
      if (data.location) {
        instructions += `You are currently located in ${data.location}. `;
      }

      const interestsArray = data.interests ?
        data.interests.split(",").map((i) => i.trim()) :
        [];
      if (interestsArray.length > 0) {
        instructions += `You are interested in ${interestsArray.join(", ")}. `;
      }

      if (data.likes) instructions += `You like ${data.likes}. `;
      if (data.dislikes) instructions += `You dislike ${data.dislikes}. `;
      if (data.lookingfor) {
        instructions += `You are looking for ${data.lookingfor}. `;
      }
      if (data.orientation) {
        instructions += `Your orientation is ${data.orientation}. `;
      }
      if (data.redflags) {
        instructions += `Some red flags for you are: ${data.redflags}. `;
      }
      instructions += " IMPORTANT: Reply directly to userMessage. ";
      instructions += "DO NOT reply to previous user questions. ";
      instructions += "Engage in conversation based on these characteristics.";
      instructions += "Behave like this character. ";

      return {
        name: `${data.name} ${data.surname || ""}`.trim(),
        instructions: instructions.trim(),
      };
    } else {
      console.warn(
        `Data for xenoprofileId "${xenoprofileId}" is malformed or ` +
          "missing required fields (name, biography). " +
          "Using default bot persona."
      );
      return {
        name: "Default Bot",
        instructions: "Be helpful and concise.",
      };
    }
  } catch (error) {
    console.error(`Error fetching xenoprofile "${xenoprofileId}":`, error);
    return {
      name: "Default Bot",
      instructions: "Be helpful and concise.",
    };
  }
}

/**
 * Fetches the persona details for the user's selected character from Firestore.
 * @param {string} userId The ID of the user.
 * @param {string} characterId The ID of the character to fetch.
 * @param {string} fallbackCharacterName
 */
async function getCharacterProfile(
  userId: string,
  characterId: string,
  fallbackCharacterName: string
): Promise<{name: string; instructions: string}> {
  const firestore = getFirestore();

  try {
    const doc = await firestore
      .collection("users")
      .doc(userId)
      .collection("characters")
      .doc(characterId)
      .get();

    if (!doc.exists) {
      console.log(
        `User character ID "${characterId}" for user "${userId}" not found.`
      );
      console.log("Using default user character persona.");
      // Fallback to the characterName provided in input if no persona found
      return {
        name: fallbackCharacterName,
        instructions: "The user is talking to you.",
      };
    }

    const data = doc.data() as UserCharacterFirestoreData | undefined;

    // Similar check as getBotPersona for essential fields
    if (
      data &&
      typeof data.name === "string" &&
      typeof data.biography === "string"
    ) {
      let instructions =
        `They are playing the role of ${data.name} ${data.surname || ""}. `;
      instructions += `Their biography states: "${data.biography}". `;
      if (data.species) {
        instructions += `They are a ${data.species}`;
        if (data.subspecies) instructions += ` (${data.subspecies})`;
        instructions += ". ";
      }
      if (data.earthage) {
        instructions += `They are ${data.earthage} Earth years old. `;
      }
      if (data.gender) instructions += `Their gender is ${data.gender}. `;
      if (data.location) {
        instructions += `They are currently located in ${data.location}. `;
      }

      const interestsArray = data.interests ?
        data.interests.split(",").map((i) => i.trim()) :
        [];
      if (interestsArray.length > 0) {
        instructions += `They are interested in ${interestsArray.join(
          ", "
        )}. `;
      }

      if (data.likes) instructions += `They like ${data.likes}. `;
      if (data.dislikes) instructions += `They dislike ${data.dislikes}. `;
      if (data.lookingfor) {
        instructions += `They are looking for ${data.lookingfor}. `;
      }
      if (data.orientation) {
        instructions += `Their orientation is ${data.orientation}. `;
      }
      if (data.redflags) {
        instructions += `Some red flags for them are: ${data.redflags}. `;
      }
      instructions += "Engage in conversation with this character in mind.";

      return {
        name: `${data.name} ${data.surname || ""}`.trim(),
        instructions: instructions.trim(),
      };
    } else {
      console.warn(
        `Data for user character "${characterId}" is malformed or` +
          "missing required fields (name, biography). " +
          "Using default user character persona."
      );
      return {
        name: fallbackCharacterName, // Fallback to the provided name
        instructions: "The user is talking to you.",
      };
    }
  } catch (error) {
    console.error(
      `Error fetching user character "${characterId}" for user "${userId}":`,
      error
    );
    return {
      name: fallbackCharacterName,
      instructions: "The user is talking to you.",
    };
  }
}

export const chatbotFlow = ai.defineFlow(
  {
    name: "chatbotFlow",
    inputSchema: ChatbotInputSchema,
    outputSchema: ChatbotOutputSchema,
  },

  async (input) => {
    console.log("Chatbot flow received input:", input);
    const {
      xenoprofileId,
      userMessage,
      userId,
      chatId,
      characterId,
      characterName,
    } = input;
    const firestore = getFirestore();

    if (!userMessage || userMessage.trim() === "") {
      return {
        reply: "I didn't receive a message. Could you please try again?",
      };
    }

    if (userMessage.length > 4000) {
      return {
        reply: "Your message is too long. Please try a shorter message.",
      };
    }
    const botPersona = await getBotPersona(xenoprofileId);

    // --- Start of new addition for user character persona ---
    // You can now fetch the user's character persona using the new function.
    const userPersona = await getCharacterProfile(
      userId,
      characterId,
      characterName
    );
    console.log(`User's character persona fetched: ${userPersona.name}`);
    // --- End of new addition ---

    // Retrieve relevant memories for the current conversation
    const relevantMemories = await ai.retrieve({
      retriever: xenoMemoryRetriever,
      query: userMessage,
      options: {k: 5}, // Retrieve top 5 relevant memories
    });

    let systemPrompt =
      `You are ${botPersona.name}. ${botPersona.instructions}` +
      "Here is information about the user you are interacting with:\n\n" +
      `${userPersona.instructions}`;

    if (relevantMemories.length > 0) {
      const memoryText = relevantMemories.map((doc) => doc.content).join("");
      systemPrompt +=
        "\n\nHere are some relevant memories about the user and your " +
        `interactions:\n${memoryText}`;
    }

    const messages: GenkitMessage[] = [];
    const messagesRef = firestore
      .collection("users")
      .doc(userId)
      .collection("chats")
      .doc(chatId)
      .collection("messages");

    try {
      const snapshot = await messagesRef.orderBy("timestamp", "asc").get();

      snapshot.docs.forEach((doc) => {
        // Now expecting role to exist from previous (corrected) writes
        const messageData = doc.data() as ChatMessage;
        if (messageData.role === "user" || messageData.role === "model") {
          messages.push({
            role: messageData.role,
            content: [{text: messageData.text}],
          });
        }
      });
      console.log(`Fetched ${messages.length} historical messages.`);
    } catch (error) {
      console.error(
        `Error fetching chat history for userId "${userId}",\n
                 chatId "${chatId}":`,
        error
      );
    }

    // Save the user's message to Firestore
    await messagesRef.add({
      role: "user",
      text: userMessage,
      timestamp: FieldValue.serverTimestamp(),
      senderId: userId,
      receiverId: xenoprofileId, // The bot's ID
      senderName: userPersona.name,
    });

    messages.push({
      role: "user",
      content: [{text: userMessage}],
    });

    try {
      const response = await ai.generate({
        model: googleAI.model("gemini-2.0-flash"),
        messages: messages, // Now the 'messages' array has the correct type
        system: systemPrompt,
        config: {
          temperature: 0.7,
          maxOutputTokens: 155,
        },
        tools: [rollDice, storeXenoMemory, retrieveXenoMemories],
      });

      const botReply = response.text;

      if (!botReply) {
        console.warn("LLM returned an empty response.");
        return {reply: "I'm not sure how to respond to that right now."};
      }

      console.log("LLM response:", botReply);

      // Save the bot's reply to Firestore
      await messagesRef.add({
        role: "model",
        text: botReply,
        timestamp: FieldValue.serverTimestamp(),
        senderId: xenoprofileId, // The bot's ID
        receiverId: userId,
        senderName: botPersona.name,
      });
      return {reply: botReply};
    } catch (error) {
      console.error("Error calling language model:", error);
      return {reply: "Sorry, I encountered an error. Please try again."};
    }
  }
);
export const chatbot = onCallGenkit(
  {
    secrets: [apiKey],
  },
  chatbotFlow
);
