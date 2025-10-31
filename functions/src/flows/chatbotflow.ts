import {genkit, z} from "genkit";
import {onCallGenkit} from "firebase-functions/https";
import {enableFirebaseTelemetry} from "@genkit-ai/firebase";
import {googleAI} from "@genkit-ai/google-genai";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";
import {getFirestore, FieldValue} from "firebase-admin/firestore";

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

const ai = genkit({
  plugins: [
    googleAI(),
  ],
});

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

/**
 * Fetches the persona details for the bot from a xenoprofile in Firestore.
 * @param {string} xenoprofileId The ID of the xenoprofile to fetch.
 */
async function getBotPersona(
  xenoprofileId: string,
): Promise<{name: string; instructions: string}> {
  const firestore = getFirestore();

  try {
    const doc = await firestore.collection("xenoprofiles")
      .doc(xenoprofileId).get();
    if (!doc.exists) {
      console.log(
        `Xenoprofile with ID "${xenoprofileId}" not found.`
      );
      console.log("Using default bot persona.");
      return {name: "Default Bot", instructions: "Be helpful and concise."};
    }

    const data = doc.data() as XenoprofileFirestoreData | undefined;

    if (data && typeof data.name === "string" &&
        typeof data.biography === "string") {
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
        data.interests.split(",").map((i) => i.trim()) : [];
      if (interestsArray.length > 0) {
        instructions += `You are interested in ${
          interestsArray.join(", ")
        }. `;
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
    console.error(
      `Error fetching xenoprofile "${xenoprofileId}":`,
      error
    );
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
  fallbackCharacterName: string,
): Promise<{name: string; instructions: string}> {
  const firestore = getFirestore();

  try {
    const doc = await firestore.collection("users")
      .doc(userId)
      .collection("characters")
      .doc(characterId)
      .get();

    if (!doc.exists) {
      console.log(
        `User character with ID "${characterId}"
        for user "${userId}" not found.`
      );
      console.log("Using default user character persona.");
      // Fallback to the characterName provided in input if no persona found
      return {name: fallbackCharacterName, instructions:
          "The user is talking to you."};
    }

    const data = doc.data() as UserCharacterFirestoreData | undefined;

    // Similar check as getBotPersona for essential fields
    if (data && typeof data.name === "string" &&
        typeof data.biography === "string") {
      let instructions =
      `They are playing the role of
      ${data.name} ${data.surname || ""}. `;
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
        data.interests.split(",").map((i) => i.trim()) : [];
      if (interestsArray.length > 0) {
        instructions += `They are interested in ${
          interestsArray.join(", ")
        }. `;
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
      xenoprofileId, userMessage, userId, chatId, characterId, characterName,
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
    const userPersona =
    await getCharacterProfile(userId, characterId, characterName);
    console.log(`User's character persona fetched: ${userPersona.name}`);
    // --- End of new addition ---

    const systemPrompt =
    `You are ${botPersona.name}. ${botPersona.instructions}` +
    `Here is information about the user you are interacting with:
     ${userPersona.instructions}`;

    const messages: GenkitMessage[] = [];
    const messagesRef = firestore.collection("users").doc(userId)
      .collection("chats").doc(chatId).collection("messages");

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
      console.log(
        `Fetched ${messages.length} historical messages for chat ${chatId}.`
      );
    } catch (error) {
      console.error(
        `Error fetching chat history for userId "${userId}",
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
        returnToolRequests: false,
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
