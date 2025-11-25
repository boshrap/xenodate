import {genkit, z} from "genkit/beta";
import {onCallGenkit} from "firebase-functions/v2/https";
import {enableFirebaseTelemetry} from "@genkit-ai/firebase";
import {googleAI} from "@genkit-ai/google-genai";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";

enableFirebaseTelemetry();
const apiKey = defineSecret("GOOGLE_GENAI_API_KEY");

if (!admin.apps.length) {
  admin.initializeApp();
}

const ai = genkit({
  plugins: [googleAI()],
});

// 1. Define the Zod schema for a single world-building item.
const worldBuildingItemSchema = z.object({
  scope: z
    .enum(["location"])
    .describe("The scope of the content, which is always 'location'."),
  location: z.string().describe("The name of the world/location."),
  category: z.string().describe(
    "The specific category of world-building detail " +
      "(e.g., 'world', 'regions', 'Oceans')."
  ),
  subcategory: z
    .union([z.array(z.string()), z.string()])
    .describe(
      "Hints for content generation; can be an array of topics or an " +
        "empty string."
    ),
  content: z
    .string()
    .describe("The generated, detailed content for the specified category."),
});

// 2. Define the schema for the form input.
const worldBuildingFormInputSchema = z.object({
  location: z.string().describe("The selected location (e.g., 'Keplia')."),
  category: z.string().describe("The selected category (e.g., 'Oceans')."),
  subcategory: z
    .string()
    .optional()
    .describe("The selected subcategory (if any)."),
  content: z.string().describe("The user-provided content for this entry."),
});

// 3. Define the final output schema for the flow.
const worldBuildingSchema = z.array(worldBuildingItemSchema);

// 4. Define the Genkit flow.
export const worldBuilderFlow = ai.defineFlow(
  {
    name: "worldBuilderFlow",
    // The flow now takes the form data as input.
    inputSchema: worldBuildingFormInputSchema,
    // The flow's output is still the full world-building array.
    outputSchema: worldBuildingSchema,
  },
  async (formInput) => {
    // This is the base JSON structure you want the AI to fill.
    const worldBuildingTemplate = [
      {
        scope: "location",
        location: "",
        category: "world",
        subcategory: [
          "Name for World",
          "Planet Details",
          "Geology",
          "Atmosphere",
          "Satellites",
          "Orbital Mechanics",
        ],
        content: "",
      },
      {
        scope: "location",
        location: "",
        category: "regions",
        subcategory: ["biomes", "zones", "borders", "states"],
        content: "",
      },
      {
        scope: "location",
        location: "",
        category: "Oceans",
        subcategory: "",
        content: "",
      },
      {
        scope: "location",
        location: "",
        category: "continents",
        subcategory: "",
        content: "",
      },
      {
        scope: "location",
        location: "",
        category: "sub-continents",
        subcategory: "",
        content: "",
      },
      {
        scope: "location",
        location: "",
        category: "local features",
        subcategory: "",
        content: "",
      },
      {
        scope: "location",
        location: "",
        category: "local location",
        subcategory: "",
        content: "",
      },
      {
        scope: "location",
        location: "",
        category: "common flora",
        subcategory: "",
        content: "",
      },
      {
        scope: "location",
        location: "",
        category: "common fauna",
        subcategory: "",
        content: "",
      },
      {
        scope: "location",
        location: "",
        category: "Local Sapients",
        subcategory: "",
        content: "",
      },
      {
        scope: "location",
        location: "",
        category: "Global Organizations",
        subcategory: "",
        content: "",
      },
      {
        scope: "location",
        location: "",
        category: "Businesses",
        subcategory: "",
        content: "",
      },
      {
        scope: "location",
        location: "",
        category: "Local Politics",
        subcategory: "",
        content: "",
      },
      {
        scope: "location",
        location: "",
        category: "Regional History",
        subcategory: "",
        content: "",
      },
    ];

    // Find the item in the template that matches the user's category.
    const userEntryIndex = worldBuildingTemplate.findIndex(
      (item) => item.category === formInput.category
    );

    if (userEntryIndex !== -1) {
      worldBuildingTemplate[userEntryIndex].content = formInput.content;
      // Also update the location for all items
      worldBuildingTemplate.forEach(
        (item) => (item.location = formInput.location)
      );
    }

    // Construct the prompt for the AI model.
    const prompt =
      "You are a creative world-building assistant for a science fiction " +
      "universe. Your task is to generate detailed lore and information " +
      "based on a user-provided entry. The user has submitted the " +
      `following information for the world of "${formInput.location}":\n\n` +
      `- Category: "${formInput.category}"\n` +
      `- Content: "${formInput.content}"\n\n` +
      "Please use this entry as the starting point. Now, fill in the " +
      "content field for ALL OTHER objects in the array with rich and " +
      "imaginative and consistent details that build upon the user's " +
      "entry. Ensure all generated information is consistent with the " +
      "provided details. For the user's original entry, you can expand " +
      "or enhance it slightly to fit the overall world, but the core " +
      "idea should be preserved. The location for all entries should be " +
      `"${formInput.location}".\n\n` +
      "Your final output must be a single JSON array that strictly " +
      "adheres to the provided schema and structure.\n\n" +
      "Template to fill out:\n" +
      `${JSON.stringify(worldBuildingTemplate, null, 2)}`;

    // Call the generative model.
    const response = await ai.generate({
      model: "googleai/gemini-2.0-flash",
      prompt: prompt,
      output: {
        schema: worldBuildingSchema,
      },
    });

    // Return the structured JSON output.
    return response.output;
  }
);

export const worldBuilder = onCallGenkit(
  {
    secrets: [apiKey],
  },
  worldBuilderFlow
);

// To run the flow server and test this flow in the Genkit Developer UI
// startFlowsServer();
