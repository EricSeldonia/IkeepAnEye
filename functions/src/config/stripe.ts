import Stripe from "stripe";
import { defineSecret } from "firebase-functions/params";

// Secrets stored in Firebase Secret Manager — never in source code
export const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
export const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");
export const stripePublishableKey = defineSecret("STRIPE_PUBLISHABLE_KEY");

/**
 * Creates a Stripe instance using the secret key from Secret Manager.
 * Call this inside a function handler, not at module load time.
 */
export function createStripe(secretKey: string): Stripe {
  return new Stripe(secretKey, { apiVersion: "2023-10-16" });
}
