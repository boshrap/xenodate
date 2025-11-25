import {genkit} from "genkit/beta";
import {googleAI} from "@genkit-ai/google-genai";
import {defineSecret} from "firebase-functions/params";

const googleApiKey = defineSecret("GOOGLE_GENAI_API_KEY");

export default genkit({
  plugins: [
    googleAI({
      apiKey: googleApiKey,
    }),
  ],
  enableTracing: true,
});
