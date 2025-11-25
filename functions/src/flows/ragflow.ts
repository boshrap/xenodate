import {onCallGenkit} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {genkit} from "genkit/beta";
import {googleAI} from "@genkit-ai/google-genai";

const apiKey = defineSecret("GOOGLE_GENAI_API_KEY");
const ai = genkit({
  plugins: [googleAI()],
});

export const exampleFlow = ai.defineFlow(
  {
    name: "exampleFlow",
  },
  async () => {
    // Flow logic goes here.

    const response = "This is a dummy response.";
    return response;
  }
);

// WARNING: This has no authentication or app check protections.
// See genkit.dev/js/auth for more information.
export const example = onCallGenkit({secrets: [apiKey]}, exampleFlow);
