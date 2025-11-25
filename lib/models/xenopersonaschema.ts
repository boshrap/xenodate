import { z } from "zod";

export const xenoPersonaSchema = z.object({
  /**
   * Unique identifier, can be left blank for new entries.
   */
  UID: z.string().optional(),
  /**
   * Primary location (e.g., Earth, Mars & FECs, Moon & NECs, Keplia).
   */
  Location: z.string().optional(),
  /**
   * Specific location (e.g., Tranquility Base, Patagonian Geocultural Commons).
   */
  Location2: z.string().optional(),
  /**
   * General category (e.g., Humanoid, Human-Like, Non-Humanoid).
   */
  Type: z.string().optional(),
  /**
   * Character's first name.
   */
  Name: z.string().optional(),
  /**
   * Character's last name.
   */
  Surname: z.string().optional(),
  /**
   * Nickname, alias, or secondary name (e.g., "Wave-Singer").
   */
  Name2: z.string().optional(),
  /**
   * Character's species (e.g., Human, Keplian, Matobun Ferrix, Featherfolk).
   */
  Species: z.string().optional(),
  /**
   * Age category (e.g., Young Adult, Adult).
   */
  RelativeAge: z.string().optional(),
  /**
   * A 1-3 sentence biography describing the character's background and role.
   */
  biography: z.string().optional(),
  /**
   * The character's gender identity (e.g., Male, Female, Neutral, Non-binary).
   */
  Gender: z.string().optional(),
  /**
   * List of hobbies, separated by commas.
   */
  Hobbies: z.string().optional(),
  /**
   * List of likes, separated by commas.
   */
  Likes: z.string().optional(),
  /**
   * List of dislikes, separated by commas.
   */
  Dislikes: z.string().optional(),
  /**
   * Potential red flags or warnings about the character.
   */
  RedFlags: z.string().optional(),
  /**
   * Sexual or romantic orientation (e.g., Straight, Bi, Queer, Gay).
   */
  Orientation: z.string().optional(),
  /**
   * URL to a character image.
   */
  imgUrl: z.string().url().optional(),
  /**
   * Is the character xenophobic? (e.g., "no").
   */
  XenoPhobic: z.string().optional(),
  /**
   * Description of education (e.g., PhD in Linguistics/Xenology, Technical Certification).
   */
  Education: z.string().optional(),
  /**
   * Formal education level (e.g., College-Grad, PhD, Self-taught).
   */
  EducationLevel: z.string().optional(),
  /**
   * Social or professional role (e.g., Business Professional, Elder).
   */
  Role: z.string().optional(),
  /**
   * Specific job title (e.g., Advertising Associate, Astroecologist, Suborbital transit mechanic).
   */
  Job: z.string().optional(),
  /**
   * Primary cultural background (e.g., American, Pan-Africanist).
   */
  Culture: z.string().optional(),
  /**
   * Specific local culture (e.g., California Southern).
   */
  LocalCulture: z.string().optional(),
  /**
   * Unique habits or eccentricities.
   */
  Quirks: z.string().optional(),
  /**
   * Sub-species or variant (e.g., Sapiens Sapiens, Sapiens Novum, Matobun Volex).
   */
  Subspecie: z.string().optional(),
  /**
   * Primary color (e.g., skin, fur, scales).
   */
  Color: z.string().optional(),
  /**
   * Secondary color or pattern (e.g., Freckles).
   */
  SubColor: z.string().optional(),
  /**
   * Additional color.
   */
  Color2: z.string().optional(),
  /**
   * Additional secondary color.
   */
  SubColor2: z.string().optional(),
  /**
   * Character's age, can be a string (e.g., "45" or "34 cycles").
   */
  Age: z.string().optional(),
  /**
   * Character's age in equivalent Earth years.
   */
  EarthAge: z.number().optional(),
  /**
   * Character's height (e.g., "6ft").
   */
  Height: z.string().optional(),
  /**
   * Character's weight (e.g., "170").
   */
  Weight: z.string().optional(),
  /**
   * Character's build (e.g., "Healthy", "Muscular").
   */
  Physique: z.string().optional(),
  /**
   * Color of the head.
   */
  HeadColor: z.string().optional(),
  /**
   * Size of the head.
   */
  HeadSize: z.string().optional(),
  /**
   * Specific details about the head.
   */
  HeadDetails: z.string().optional(),
  /**
   * Specific details about the chest.
   */
  ChestDetails: z.string().optional(),
  /**
   * Specific details about the limbs.
   */
  LimbDetails: z.string().optional(),
  /**
   * Secondary gender field, possibly for physical description.
   */
  Gender2: z.string().optional(),
  /**
   * Notes on mental traits (e.g., "sharp, savvy, good with words").
   */
  Mental: z.string().optional(),
  /**
   * Notes on physical traits (e.g., "average strength, good understanding of animals").
   */
  Physical: z.string().optional(),
  /**
   * Notes on emotional traits (e.g., "even tempered, patient").
   */
  Emotional: z.string().optional(),
});

// To export the type for use in TypeScript
export type XenoPersona = z.infer<typeof xenoPersonaSchema>;