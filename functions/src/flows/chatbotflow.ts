import {genkit, z} from 'genkit';
import {onCallGenkit} from "firebase-functions/https";
import {enableFirebaseTelemetry} from '@genkit-ai/firebase';
import {googleAI} from "@genkit-ai/googleai"; // Fixed import
import { defineSecret } from "firebase-functions/params";
import * as admin from 'firebase-admin';
import { getFirestore } from 'firebase-admin/firestore';
interface XenoprofileFirestoreData {
  id: string;
  name: string;
  surname: string;
  earthage?: number | null; // Matches Dart's nullable int
  gender: string;
  interests: string; // Stored as a comma-separated string in Firestore
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
  // Add other fields if they are stored in Firestore and relevant for the persona
}
enableFirebaseTelemetry();
const apiKey = defineSecret("GOOGLE_GENAI_API_KEY");

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

// Initialize Genkit with Firebase integration
const ai = genkit({
  plugins: [
    googleAI(),
  ],
  logLevel: 'debug',
  enableTracingAndMetrics: true,
});

// Define the input schema for your flow, matching what Flutter sends
const ChatbotInputSchema = z.object({
  xenoprofileId: z.string(),
  userMessage: z.string(),
  history: z.array(z.object({
    role: z.enum(['user', 'model']), // 'user' for user messages, 'model' for AI messages
    text: z.string(),
  })).optional(), // Make history optional, though your Flutter code sends it
});

// Define the output schema for your flow, matching what Flutter expects
const ChatbotOutputSchema = z.object({
  reply: z.string(),
});

// Define the Genkit Flow
async function getBotPersona(xenoprofileId: string): Promise<{ name: string; instructions: string }> {
  const firestore = getFirestore();

  try {
    const doc = await firestore.collection('xenoprofiles').doc(xenoprofileId).get();
    if (!doc.exists) {
      console.log(`Xenoprofile with ID '${xenoprofileId}' not found. Using default persona.`);
      return { name: "Default Bot", instructions: "Be helpful and concise." };
    }

    // It's good practice to cast the data to your defined interface for type safety
    const data = doc.data() as XenoprofileFirestoreData | undefined;

    // Validate the fetched data
    if (data && typeof data.name === 'string' && typeof data.biography === 'string') {
      // Construct more detailed instructions based on the Xenoprofile data
      let instructions = `You are ${data.name} ${data.surname || ''}. `;
      instructions += `Your biography states: "${data.biography}". `;
      if (data.species) instructions += `You are a ${data.species}`;
      if (data.subspecies) instructions += ` (${data.subspecies}). `;
      if (data.earthage) instructions += `You are ${data.earthage} Earth years old. `;
      if (data.gender) instructions += `Your gender is ${data.gender}. `;
      if (data.location) instructions += `You are currently located in ${data.location}. `;

      // Parse interests if they are relevant for the persona
      const interestsArray = data.interests ? data.interests.split(',').map(i => i.trim()) : [];
      if (interestsArray.length > 0) {
        instructions += `You are interested in ${interestsArray.join(', ')}. `;
      }

      if (data.likes) instructions += `You like ${data.likes}. `;
      if (data.dislikes) instructions += `You dislike ${data.dislikes}. `;
      if (data.lookingfor) instructions += `You are looking for ${data.lookingfor}. `;
      if (data.orientation) instructions += `Your orientation is ${data.orientation}. `;
      if (data.redflags) instructions += `Some red flags for you are: ${data.redflags}. `;

      // Add a general instruction
      instructions += "Engage in conversation based on these characteristics. Behave like this character.";

      return {
        name: `${data.name} ${data.surname || ''}`.trim(), // Combine name and surname for the bot's display name
        instructions: instructions.trim(),
      };
    } else {
      console.warn(`Data for xenoprofileId '${xenoprofileId}' is malformed or missing required fields (name, biography). Using default persona.`);
      return { name: "Default Bot", instructions: "Be helpful and concise." };
    }
  } catch (error) {
    console.error(`Error fetching xenoprofile '${xenoprofileId}':`, error);
    // Fallback to default persona in case of other errors during fetch
    return { name: "Default Bot", instructions: "Be helpful and concise." };
  }
}

export const chatbotFlow = ai.defineFlow(
  {
    name: 'chatbotFlow', // This name will be used for the Firebase Function
    inputSchema: ChatbotInputSchema,
    outputSchema: ChatbotOutputSchema,
  },

  async (input) => {
    console.log('Chatbot flow received input:', input);
    const { xenoprofileId, userMessage, history } = input;
    if (!userMessage || userMessage.trim() === '') {
      return { reply: "I didn't receive a message. Could you please try again?" };
    }

    if (userMessage.length > 4000) { // Reasonable limit
      return { reply: "Your message is too long. Please try a shorter message." };
    }
    const botPersona = await getBotPersona(xenoprofileId);

    const systemPrompt = `You are ${botPersona.name}. ${botPersona.instructions}`;

    const messages = [];

    if (history && history.length > 0) {
      history.forEach(histMessage => {
        messages.push({
          role: histMessage.role === 'user' ? 'user' : 'model', // Explicit role mapping
          content: [{ text: histMessage.text }],
        });
      });
    }

    messages.push({
      role: 'user',
      content: [{ text: userMessage }],
    });

    // 3. Call the Generative Model
    try {
      const response = await ai.generate({
        model: googleAI.model('gemini-2.0-flash'),
        messages: messages,
        system: systemPrompt, // Fixed: use 'system' instead of 'systemInstruction'
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
      // It's good practice to provide a graceful fallback or error message
      return { reply: "Sorry, I encountered an error. Please try again." };
    }
  }
);

export const chatbot = onCallGenkit({
  // Uncomment to enable AppCheck. This can reduce costs by ensuring only your Verified
  // app users can use your API. Read more at https://firebase.google.com/docs/app-check/cloud-functions
  // enforceAppCheck: true,

  // authPolicy can be any callback that accepts an AuthData (a uid and tokens dictionary) and the
  // request data. The isSignedIn() and hasClaim() helpers can be used to simplify. The following
  // will require the user to have the email_verified claim, for example.
  // authPolicy: hasClaim("email_verified"),

  // Grant access to the API key to this function:
  secrets: [apiKey],
}, chatbotFlow);
