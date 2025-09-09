// src/flows/recipeFlow.ts
import { z } from 'genkit';
import { type AI } from '../index'; // Import the TYPE of ai, not the instance directly if possible

// Define input schema
const RecipeInputSchema = z.object({
  ingredient: z.string().describe('Main ingredient or cuisine type'),
  dietaryRestrictions: z.string().optional().describe('Any dietary restrictions'),
});

// Define output schema
const RecipeSchema = z.object({
  title: z.string(),
  description: z.string(),
  prepTime: z.string(),
  cookTime: z.string(),
  servings: z.number(),
  ingredients: z.array(z.string()),
  instructions: z.array(z.string()),
  tips: z.array(z.string()).optional(),
});

// Define a function that creates the flow
// This function will be called after 'ai' is initialized
export function initializeRecipeGeneratorFlow(aiInstance: AI) { // Pass the initialized 'ai' instance
  const recipeGeneratorFlow = aiInstance.defineFlow(
    {
      name: 'recipeGeneratorFlow',
      inputSchema: RecipeInputSchema,
      outputSchema: RecipeSchema,
    },
    async (input) => {
      const prompt = `Create a recipe with the following requirements:
        Main ingredient: ${input.ingredient}
        Dietary restrictions: ${input.dietaryRestrictions || 'none'}`;

      const { output } = await aiInstance.generate({ // Use the passed aiInstance
        prompt,
        output: { schema: RecipeSchema },
      });

      if (!output) throw new Error('Failed to generate recipe');
      return output;
    }
  );
  return recipeGeneratorFlow;
}

// You might then export the flow after initialization in your main file or index.ts
// For example, in index.ts:
/*
import { initializeRecipeGeneratorFlow } from './flows/recipeFlow';

// ... initialize your 'ai' instance first ...
export const ai = // ... your ai initialization code ...;
export type AI = typeof ai; // Export the type if needed

export const recipeGeneratorFlow = initializeRecipeGeneratorFlow(ai);
*/
