import * as functions from "firebase-functions";
import { db } from "../../config/firebase";
import {
  createStripe,
  stripeSecretKey,
  stripePublishableKey,
} from "../../config/stripe";

/**
 * Triggered when a new Firebase Auth user is created.
 * Creates the Firestore user document and a Stripe customer.
 */
export const createUserRecord = functions
  .runWith({ secrets: [stripeSecretKey, stripePublishableKey] })
  .auth.user()
  .onCreate(async (user) => {
    const stripe = createStripe(stripeSecretKey.value());

    let stripeCustomerId: string | undefined;
    try {
      const customer = await stripe.customers.create({
        email: user.email,
        name: user.displayName,
        metadata: { firebaseUID: user.uid },
      });
      stripeCustomerId = customer.id;
    } catch (err) {
      console.error("Failed to create Stripe customer:", err);
    }

    await db
      .collection("users")
      .doc(user.uid)
      .set({
        email: user.email ?? "",
        displayName: user.displayName ?? null,
        stripeCustomerId: stripeCustomerId ?? null,
        createdAt: new Date(),
        lastSignInAt: new Date(),
      });

    console.log(`Created user record for ${user.uid}`);
  });
