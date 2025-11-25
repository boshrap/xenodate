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

// 1. Define the Zod schema for a single species-building item.
const speciesBuildingItemSchema = z.object({
  scope: z
    .enum(["species"])
    .describe("The scope of the content, which is always 'species'."),
  species_name: z
    .array(z.string())
    .describe("An array of all possible species names in the universe."),
  category: z.string().describe(
    "The specific category of species detail " +
      "(e.g., 'biology', 'Culture', 'History')."
  ),
  subcategory: z
    .union([z.array(z.string()), z.string()])
    .describe(
      "Hints for content generation; can be an array of topics or an " +
        "empty string."
    ),
  content: z.string().describe(
    "The generated, detailed content for the specified category or " +
      "subcategory."
  ),
});

// 2. Define the final output schema for the flow.
const speciesBuildingSchema = z.array(speciesBuildingItemSchema);

// 3. Define the Genkit flow.
export const speciesBuilderFlow = ai.defineFlow(
  {
    name: "speciesBuilderFlow",
    inputSchema: z.string().describe(
      "The subject or theme for species generation," +
      "(e.g., \"The Ferrix, a silicon-based lifeform" +
          "from a high-gravity world\")."
    ),
    outputSchema: speciesBuildingSchema,
  },
  async (subject) => {
    const speciesBuildingTemplate = [
      {
        scope: "species",
        species_name: "",
        category: "name",
        subcategory: ["Demonym", "Name for World"],
        content: "",
      },
      {
        scope: "species",
        species_name: "",
        category: "biology",
        subcategory: [
          "Anatomy",
          "Maturation Period",
          "Diet & Digestion",
          "Evolutionary History",
          "Reproduction",
          "Adaptations",
        ],
        content: "",
      },
      {
        scope: "species",
        species_name: "",
        category: "Kinship",
        subcategory: ["Siblings", "Parents", "family", "clan", "tribes"],
        content: "",
      },
      {
        scope: "species",
        species_name: "",
        category: "Territory",
        subcategory: "",
        content: "",
      },
      {
        scope: "species",
        species_name: "",
        category: "History",
        subcategory: [
          "Evolutionary History",
          "Civilization History",
          "Ancient History",
          "Recent History",
          "Natural History",
        ],
        content: "",
      },
      {
        scope: "species",
        species_name: "",
        category: "Culture",
        subcategory: ["Ethnography", "Ethnic Groups", "Clothing"],
        content: "",
      },
      {
        scope: "species",
        species_name: "",
        category: "Architecture",
        subcategory: [
          "Materials",
          "Homes",
          "Habitation Style",
          "Decoration",
          "Social Organization",
        ],
        content: "",
      },
      {
        scope: "species",
        species_name: "",
        category: "Technology",
        subcategory: [
          "Transportation",
          "Medicine",
          "Social",
          "Personal",
          "Agricultural",
          "Cultural",
          "Resource Extraction",
        ],
        content: "",
      },
      {
        scope: "species",
        species_name: "",
        category: "Language",
        subcategory: [
          "Grammar",
          "Writing Systems",
          "Languages",
          "Interspecies Communication",
          "Vocabulary",
          "Slang",
        ],
        content: "",
      },
      {
        scope: "species",
        species_name: "",
        category: "Society",
        subcategory: [
          "Politics",
          "Religions",
          "Organizations",
          "Councils",
          "Governments",
          "Leadership",
          "Class Dynamics",
        ],
        content: "",
      },
    ];

    const prompt =
      "You are a creative xenobiologist and cultural anthropologist for a " +
      "science fiction universe. Your task is to generate detailed lore for " +
      `a fictional species based on the following subject: "${subject}".\n\n` +
      "Please generate content for EACH of the categories listed in the " +
      "JSON template below. Fill in the \"content\" field for every object " +
      "in the array with rich, imaginative, and consistent details. The " +
      "generated text should be appropriate for the given \"category\" and " +
      "any \"subcategory\" hints.\n\n" +
      "Your final output must be a single JSON array that strictly " +
      "adheres to the provided schema and structure.\n\n" +
      "Template to fill out:\n" +
      `${JSON.stringify(speciesBuildingTemplate, null, 2)}`;

    const response = await ai.generate({
      model: "googleai/gemini-2.0-flash",
      prompt: prompt,
      output: {
        schema: speciesBuildingSchema,
      },
    });

    return response.output;
  }
);

const speciesDetailInputSchema = z.object({
  subject: z.string().describe(
    "The core concept for the species (e.g., \"The Ferrix\", a" +
      "silicon-based lifeform from a high-gravity world)."
  ),
  speciesName: z
    .string()
    .describe("The specific name of the species to generate content for."),
  category: z.string().describe(
    "The specific category of detail to generate (e.g., 'biology', 'Culture')."
  ),
  subcategory: z
    .union([z.array(z.string()), z.string()])
    .describe(
      "An array of topics or a string of hints to guide content generation " +
        "for the category."
    ),
});

export const generateSpeciesDetailFlow = ai.defineFlow(
  {
    name: "generateSpeciesDetailFlow",
    inputSchema: speciesDetailInputSchema,
    outputSchema: z.string(),
  },
  async ({subject, speciesName, category, subcategory}) => {
    const prompt =
      "You are a creative xenobiologist and cultural anthropologist for a " +
      "science fiction universe. Your task is to generate a detailed piece " +
      "of lore for the fictional species known as the " +
      `"${speciesName}".\n\n` +
      `The overarching concept for this species is: "${subject}".\n\n` +
      "Please generate rich, imaginative, and consistent content " +
      "specifically for the following category:\n\n" +
      `- Category: "${category}"\n` +
      `- Subcategory Hints: "${JSON.stringify(subcategory)}".\n\n` +
      "Focus only on generating the text for this specific category. Do not " +
      "output JSON, just the narrative content.";

    const response = await ai.generate({
      model: "googleai/gemini-2.0-flash",
      prompt: prompt,
      output: {
        format: "text",
      },
    });

    return response.output;
  }
);

export const generateSpeciesDetail = onCallGenkit(
  {
    secrets: [apiKey],
  },
  generateSpeciesDetailFlow
);

export const speciesBuilder = onCallGenkit(
  {
    secrets: [apiKey],
  },
  speciesBuilderFlow
);
