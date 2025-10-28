import {genkit, z} from 'genkit';
import {onCallGenkit} from "firebase-functions/https";
import {enableFirebaseTelemetry} from '@genkit-ai/firebase';
import {googleAI} from "@genkit-ai/google-genai";
import { defineSecret } from "firebase-functions/params";
import * as admin from 'firebase-admin';
import { getFirestore } from 'firebase-admin/firestore';
interface XenoprofileFirestoreData {
  id: string;
  name: string;
  surname: string;
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
  xenoprofileId: z.string(),
  userMessage: z.string(),
  history: z.array(z.object({
    role: z.enum(['user', 'model']),
    text: z.string(),
  })).optional(),
});

const ChatbotOutputSchema = z.object({
  reply: z.string(),
});

async function getBotPersona(xenoprofileId: string): Promise<{ name: string; instructions: string }> {
  const firestore = getFirestore();

  try {
    const doc = await firestore.collection('xenoprofiles').doc(xenoprofileId).get();
    if (!doc.exists) {
      console.log(`Xenoprofile with ID '${xenoprofileId}' not found. Using default persona.`);
      return { name: "Default Bot", instructions: "Be helpful and concise." };
    }

    const data = doc.data() as XenoprofileFirestoreData | undefined;

    if (data && typeof data.name === 'string' && typeof data.biography === 'string') {
      let instructions = `You are ${data.name} ${data.surname || ''}. `;
      instructions += `Your biography states: "${data.biography}". `;
      if (data.species) instructions += `You are a ${data.species}`;
      if (data.subspecies) instructions += ` (${data.subspecies}). `;
      if (data.earthage) instructions += `You are ${data.earthage} Earth years old. `;
      if (data.gender) instructions += `Your gender is ${data.gender}. `;
      if (data.location) instructions += `You are currently located in ${data.location}. `;

      const interestsArray = data.interests ? data.interests.split(',').map(i => i.trim()) : [];
      if (interestsArray.length > 0) {
        instructions += `You are interested in ${interestsArray.join(', ')}. `;
      }

      if (data.likes) instructions += `You like ${data.likes}. `;
      if (data.dislikes) instructions += `You dislike ${data.dislikes}. `;
      if (data.lookingfor) instructions += `You are looking for ${data.lookingfor}. `;
      if (data.orientation) instructions += `Your orientation is ${data.orientation}. `;
      if (data.redflags) instructions += `Some red flags for you are: ${data.redflags}. `;

      instructions += "Engage in conversation based on these characteristics. Behave like this character.";

      return {
        name: `${data.name} ${data.surname || ''}`.trim(),
        instructions: instructions.trim(),
      };
    } else {
      console.warn(`Data for xenoprofileId '${xenoprofileId}' is malformed or missing required fields (name, biography). Using default persona.`);
      return { name: "Default Bot", instructions: "Be helpful and concise." };
    }
  } catch (error) {
    console.error(`Error fetching xenoprofile '${xenoprofileId}':`, error);
    return { name: "Default Bot", instructions: "Be helpful and concise." };
  }
}

export const chatbotFlow = ai.defineFlow(
  {
    name: 'chatbotFlow',
    inputSchema: ChatbotInputSchema,
    outputSchema: ChatbotOutputSchema,
  },

  async (input) => {
    console.log('Chatbot flow received input:', input);
    const { xenoprofileId, userMessage, history } = input;
    if (!userMessage || userMessage.trim() === '') {
      return { reply: "I didn't receive a message. Could you please try again?" };
    }

    if (userMessage.length > 4000) {
      return { reply: "Your message is too long. Please try a shorter message." };
    }
    const botPersona = await getBotPersona(xenoprofileId);

    const systemPrompt = `You are ${botPersona.name}. ${botPersona.instructions}`;

    // Define the expected message type for Genkit's generate function
    interface GenkitMessagePart {
      text: string;
    }

    interface GenkitMessage {
      role: 'user' | 'model' | 'system' | 'tool'; // Explicitly define allowed roles as per Genkit's expectation
      content: GenkitMessagePart[];
    }

    const messages: GenkitMessage[] = []; // Explicitly type the array

    if (history && history.length > 0) {
      history.forEach(histMessage => {
        messages.push({
          role: histMessage.role, // This will be 'user' or 'model', which is compatible
          content: [{ text: histMessage.text }],
        });
      });
    }

    messages.push({
      role: 'user',
      content: [{ text: userMessage }],
    });

    try {
      const response = await ai.generate({
        model: googleAI.model('gemini-2.0-flash'),
        messages: messages, // Now the 'messages' array has the correct type
        system: systemPrompt,
        config: {
          temperature: 0.7,
          maxOutputTokens: 500,
        },
        returnToolRequests: false
      });

      const botReply = response.text;

      if (!botReply) {
        console.warn('LLM returned an empty response.');
        return { reply: "I'm not sure how to respond to that right now." };
      }

      console.log('LLM response:', botReply);
      return { reply: botReply };

    } catch (error) {
      console.error('Error calling language model:', error);
      return { reply: "Sorry, I encountered an error. Please try again." };
    }
  }
);

export const chatbot = onCallGenkit({
  secrets: [apiKey],
}, chatbotFlow);
