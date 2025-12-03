import {genkit, z} from "genkit/beta";
import {googleAI} from "@genkit-ai/google-genai";
import {onCallGenkit} from "firebase-functions/https";
import {
  defineFirestoreRetriever,
  enableFirebaseTelemetry,
} from "@genkit-ai/firebase";
import {Document} from "genkit/retriever";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {chunk} from "llm-chunk";

const apiKey = defineSecret("GOOGLE_GENAI_API_KEY");

const ai = genkit({
  plugins: [googleAI()],
});

// Initialize Firebase Admin app and Firestore instance
enableFirebaseTelemetry();

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = getFirestore();
const xenoworldbookCollection = db.collection("xenoworldbook");

// Define the embedder model to use
const EMBEDDER_MODEL = "text-embedding-004";

// Define inputSchema separately to allow for type inference
const worldIndexerInputSchema = z.object({
  scope: z.string().describe("Scope of the entry (location or species)"),
  location: z.string().nullish().describe("Location for world-building"),
  species: z.string().nullish().describe("Species for world-building"),
  category: z.string().describe("Category for world-building"),
  subcategory: z.string().nullish()
    .describe("Subcategory for world-building"),
  title: z.string().describe("Title for the world-building entry"),
  tags: z.array(z.string()).nullish().describe(
    "Tags for the world-building entry"),
  content: z.string().describe("Content details for world-building"),
});

// Define a type alias for the input using z.infer
type WorldIndexerInput = z.infer<typeof worldIndexerInputSchema>;

// Define a type for the metadata properties from the input schema.
const worldIndexerMetadataSchema =
  worldIndexerInputSchema.omit({content: true});
type WorldIndexerMetadata = z.infer<typeof worldIndexerMetadataSchema>;

// An intersection type for the data stored in Firestore.
type XenoworldbookDocument = WorldIndexerMetadata & {
  content: string;
  embedding: FieldValue;
};

// Define the retriever for querying the xenoworldbook collection
export const xenoWorldbookRetriever = defineFirestoreRetriever(ai, {
  name: "xenoworldbook",
  firestore: db,
  collection: "xenoworldbook",
  contentField: "content",
  vectorField: "embedding",
  embedder: googleAI.embedder(EMBEDDER_MODEL),
});

export const xenoWorldbookIndexer = ai.defineIndexer(
  {
    name: "xenoworldbook",
  },
  async (docs) => {
    for (const doc of docs) {
      const embedding = (await ai.embed({
        embedder: googleAI.embedder(EMBEDDER_MODEL),
        content: doc.text,
      }))[0];

      const documentData: XenoworldbookDocument = {
        ...(doc.metadata as WorldIndexerMetadata),
        content: doc.text,
        embedding: FieldValue.vector(embedding.embedding),
      };

      // Remove undefined metadata fields
      Object.keys(documentData).forEach((key) => {
        if (documentData[key as keyof XenoworldbookDocument] === undefined) {
          delete documentData[key as keyof XenoworldbookDocument];
        }
      });

      await xenoworldbookCollection.add(documentData);
    }
  }
);

export const worldIndexerFlow = ai.defineFlow(
  {
    name: "worldIndexer",
    inputSchema: worldIndexerInputSchema, // Use the defined schema
    outputSchema: z.object({
      success: z.boolean(),
      documentsIndexed: z.number(),
      error: z.string().optional(),
    }),
  },
  // Explicitly type the destructured parameters
  async ({
    scope,
    location,
    species,
    category,
    subcategory,
    title,
    tags,
    content,
  }: WorldIndexerInput) => {
    try {
      const chunkingConfig: {
        minLength: number;
        maxLength: number;
        splitter: "sentence";
        overlap: number;
        delimiters: string;
      } = {
        minLength: 1000,
        maxLength: 2000,
        splitter: "sentence",
        overlap: 100,
        delimiters: "",
      };

      // Divide the content into segments
      const chunks = await ai.run(
        "chunk-it",
        async () => chunk(content, chunkingConfig)
      );

      // Convert chunks of text into documents to store in the index.
      const documents = chunks.map((textChunk) => {
        return Document.fromText(textChunk, {
          scope,
          location,
          species,
          category,
          subcategory,
          title,
          tags,
        });
      });

      // Add documents to the index
      await ai.index({
        indexer: xenoWorldbookIndexer,
        documents,
      });

      const documentsIndexedCount = documents.length;

      return {
        success: true,
        documentsIndexed: documentsIndexedCount,
      };
    } catch (err) {
      // For unexpected errors that throw exceptions
      return {
        success: false,
        documentsIndexed: 0,
        error: err instanceof Error ? err.message : String(err),
      };
    }
  },
);

const queryWorldbookFlow = ai.defineFlow(
  {
    name: "queryWorldbook",
    inputSchema: z.object({
      query: z.string().describe("The search query"),
      limit: z.number().optional().default(3).describe(
        "Number of results to return"),
      location: z.string().optional().describe("Filter by location"),
    }),
    outputSchema: z.array(z.object({
      content: z.string(),
      metadata: worldIndexerMetadataSchema.optional(),
    })),
  },
  async ({query, limit, location}) => {
    const docs = await ai.retrieve({
      retriever: xenoWorldbookRetriever,
      query: query,
      options: {limit},
    });

    let filteredDocs = docs;
    if (location) {
      filteredDocs = docs.filter((d) => d.metadata?.location === location);
    }

    // By asserting the type of d.metadata, we resolve the mismatch
    return filteredDocs.map((d) => ({
      content: d.text,
      metadata: d.metadata as WorldIndexerMetadata | undefined,
    }));
  }
);
export const queryWorldbook = onCallGenkit(
  {secrets: [apiKey]},
  queryWorldbookFlow,
);

export const worldIndexer = onCallGenkit(
  {secrets: [apiKey]},
  worldIndexerFlow,
);

/**
 * Defines and returns a tool for the chatbot to consult the Xenoworldbook.
 * @param {object} ai - The Genkit AI instance.
 * @return {Array<any>} An array containing the defined worldbook tools.
 */
export function defineXenoWorldbookTools(ai: ReturnType<typeof genkit>) {
  const consultXenoWorldbook = ai.defineTool(
    {
      name: "consultXenoWorldbook",
      description: "Consults the Xenoworldbook to get information about the " +
        "world, species, locations, lore, and other static universe details. " +
        "Use this when the user asks about the setting or background info.",
      inputSchema: z.object({
        query: z.string().describe("The query to search the worldbook for."),
      }),
      outputSchema: z.string().describe("The content found in the worldbook."),
    },
    async ({query}) => {
      const docs = await ai.retrieve({
        retriever: xenoWorldbookRetriever,
        query: query,
        options: {limit: 3},
      });

      if (docs.length === 0) {
        return "No relevant information found in the Xenoworldbook.";
      }

      return docs.map((d) => d.text).join("\n\n");
    }
  );

  return [consultXenoWorldbook];
}
