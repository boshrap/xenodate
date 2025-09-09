    import { googleAI } from '@genkit-ai/googleai';
    import { genkit } from 'genkit';
    import { recipeGeneratorFlow } from './flows/recipeFlow';

    // Initialize Genkit
    export const ai = genkit({
      plugins: [googleAI()],
      model: googleAI.model('gemini-2.5-flash', {
        temperature: 0.8,
      }),
      // You might configure logging, telemetry, etc. here
    });


    // Export your flows so they can be discovered by Genkit tools or deployed
    export { recipeGeneratorFlow };

    // You might have a main function here for local testing if needed
    // async function main() {
    //   // ... test your flows
    // }
    // main().catch(console.error);
    