import {genkit, z} from "genkit/beta";
import {defineFirestoreRetriever} from "@genkit-ai/firebase";
import {googleAI} from "@genkit-ai/google-genai";
import {applicationDefault, initializeApp, getApps} from "firebase-admin/app";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
// Removed unused imports: chunk, path

// Change these values to match your Firestore config/schema
const indexConfig = {
  collection: "xenoMemories",
  contentField: "text",
  vectorField: "embedding",
  embedder: googleAI.embedder("text-embedding-004"),
};

// Initialize Firebase Admin app and Firestore instance


// Initialize Firebase Admin app and Firestore instance safely
const app = getApps().length === 0 ?
  initializeApp({credential: applicationDefault()}) :
  getApps()[0];
const firestore = getFirestore(app);

/**
 * Defines and returns a set of tools for managing
 * long-term memory using Firestore.
 * This includes tools for storing and retrieving memories (text embeddings).
 * @param {object} ai - The Genkit AI instance.
 * @return {Array<any>} An array containing the defined memory tools.
 */
export function defineXenoMemoryTools(ai: ReturnType<typeof genkit>) {
  const xenoMemoriesRetriever = defineFirestoreRetriever(ai, {
    name: "xenomemories",
    firestore,
    ...indexConfig,
  });

  // 2. Define the 'storeXenoMemory' tool.
  const storeXenoMemory = ai.defineTool(
    {
      name: "storeXenoMemory",
      description: "Stores a piece of memory or information in the long-term" +
        "memory. Use this to remember important details from the conversation" +
        "or about the user.",
      inputSchema: z.object({
        text: z.string().describe("The text content to store as a memory."),
        characterId: z.string().describe(
          "The ID of the character associated with this memory."),
        xenoprofileId: z.string().describe(
          "The ID of the xenoprofile associated with this memory."),
      }),
      outputSchema: z.object({
        success: z.boolean().describe(
          "Whether the memory was stored successfully."),
        message: z.string().describe(
          "Status message describing the result."),
      }),
    },
    async ({text, characterId, xenoprofileId}) => {
      try {
        // Embed the input text to create a vector.
        const embedding = (await ai.embed({
          embedder: indexConfig.embedder,
          content: text,
        }))[0].embedding;
        console.log(`Embedding dimension: ${embedding.length}`);

        await firestore.collection(indexConfig.collection).add({
          [indexConfig.vectorField]: FieldValue.vector(embedding),
          [indexConfig.contentField]: text,
          characterId: characterId,
          xenoprofileId: xenoprofileId,
          timestamp: FieldValue.serverTimestamp(),
        });
        console.log(`Memory stored: "${text.substring(
          0, Math.min(text.length, 50))}..."`);
        return {
          success: true,
          message: "Memory stored successfully.",
        };
      } catch (error: unknown) {
        console.error("Error storing memory:", error);
        const err = error as { code?: number; message?: string };
        if (err.code === 9 || err.message?.includes("FAILED_PRECONDITION")) {
          console.error(
            "POSSIBLE MISSING INDEX: Ensure 'xenoMemories' collection has " +
            "a Vector Index on 'embedding' field."
          );
        }
        return {
          success: false,
          message: `Failed to store memory: ${(error as Error).message}`,
        };
      }
    },
  );

  // 3. Define the 'retrieveXenoMemories' tool.
  const retrieveXenoMemories = ai.defineTool(
    {
      name: "retrieveXenoMemories",
      description: "Retrieves relevant memories or information from the " +
        "long-term memory based on a query. Use this to recall past " +
        "conversations or facts about a user.",
      inputSchema: z.object({
        query: z.string().describe(
          "The query to search for relevant memories."),
        k: z.number().int().min(1).default(3).describe(
          "The number of top relevant memories to retrieve."),
        characterId: z.string().describe(
          "The ID of the character to filter memories by."),
        xenoprofileId: z.string().describe(
          "The ID of the xenoprofile to filter memories by."),
      }),
      outputSchema: z.array(z.object({
        content: z.string().describe(
          "The text content of the retrieved memory."),
        score: z.number().optional().describe(
          "The relevance score of the memory."),
      })).describe(
        "An array of retrieved memories with " +
        "their content and relevance score."),
    },
    async ({query, k, characterId, xenoprofileId}) => {
      try {
        const results = await ai.retrieve({
          retriever: xenoMemoriesRetriever,
          query: query,
          options: {
            limit: k,
            where: [
              {
                field: "characterId",
                op: "==",
                value: characterId,
              },
              {
                field: "xenoprofileId",
                op: "==",
                value: xenoprofileId,
              },
            ],
          },
        });
        console.log(`Retrieved ${results.length} memories for query:
            "${query.substring(0, Math.min(query.length, 50))}..."`);
        // Map the results to the specified output schema.
        return results.map((r) => ({
          content: r.text,
          score: (r as { score?: number }).score,
        }));
      } catch (error: unknown) {
        console.error("Error retrieving memories:", error);
        return []; // Return an empty array on error to prevent flow failure
      }
    },
  );

  return [storeXenoMemory, retrieveXenoMemories];
}
