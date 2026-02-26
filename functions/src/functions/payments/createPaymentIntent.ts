import * as functions from "firebase-functions";
import { db } from "../../config/firebase";
import {
  createStripe,
  stripeSecretKey,
  stripePublishableKey,
} from "../../config/stripe";
import { Order } from "../../types/order";

interface CreatePaymentIntentRequest {
  orderId: string;
}

interface CreatePaymentIntentResponse {
  clientSecret: string;
  ephemeralKey: string;
  customerId: string;
  publishableKey: string;
}

/**
 * Callable Cloud Function: creates a Stripe PaymentIntent for an order.
 *
 * Security:
 * - Verifies the caller's Firebase Auth token
 * - Validates order.userId == caller's uid
 * - Reads price server-side from Firestore (never trusts client amount)
 * - Stripe secret key is injected from Secret Manager
 */
export const createPaymentIntent = functions
  .runWith({ secrets: [stripeSecretKey, stripePublishableKey] })
  .https.onCall(
    async (
      data: CreatePaymentIntentRequest,
      context
    ): Promise<CreatePaymentIntentResponse> => {
      // Auth check
      if (!context.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "Authentication required."
        );
      }

      const { orderId } = data;
      if (!orderId || typeof orderId !== "string") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "orderId is required."
        );
      }

      // Load order from Firestore
      const orderRef = db.collection("orders").doc(orderId);
      const orderSnap = await orderRef.get();
      if (!orderSnap.exists) {
        throw new functions.https.HttpsError("not-found", "Order not found.");
      }
      const order = orderSnap.data() as Order;

      // Ownership check — prevent cross-user payment intent creation
      if (order.userId !== context.auth.uid) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "You do not have permission to pay for this order."
        );
      }

      if (order.status !== "pending_payment") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          `Order status is '${order.status}', not payable.`
        );
      }

      // Load user's Stripe customer ID (written by createUserRecord CF)
      const userSnap = await db.collection("users").doc(context.auth.uid).get();
      const stripeCustomerId = userSnap.data()?.stripeCustomerId as
        | string
        | undefined;
      if (!stripeCustomerId) {
        throw new functions.https.HttpsError(
          "internal",
          "Stripe customer not found."
        );
      }

      const stripe = createStripe(stripeSecretKey.value());

      // Read authoritative price from Firestore product document
      const productSnap = await db
        .collection("products")
        .doc(order.productId)
        .get();
      if (!productSnap.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Product not found."
        );
      }
      const serverPrice = productSnap.data()?.priceInCents as number;
      const shippingCents = 999;
      const taxCents = Math.round(serverPrice * 0.08);
      const totalCents = serverPrice + shippingCents + taxCents;

      // Update order pricing with server-computed values
      await orderRef.update({
        "pricing.subtotalCents": serverPrice,
        "pricing.shippingCents": shippingCents,
        "pricing.taxCents": taxCents,
        "pricing.totalCents": totalCents,
        updatedAt: new Date(),
      });

      // Create ephemeral key for PaymentSheet customer session
      const ephemeralKey = await stripe.ephemeralKeys.create(
        { customer: stripeCustomerId },
        { apiVersion: "2024-12-18.acacia" }
      );

      // Create PaymentIntent
      const paymentIntent = await stripe.paymentIntents.create({
        amount: totalCents,
        currency: "usd",
        customer: stripeCustomerId,
        metadata: {
          orderId,
          userId: context.auth.uid,
          productId: order.productId,
        },
        automatic_payment_methods: { enabled: true },
      });

      // Store payment intent ID on the order (not yet paid — webhook confirms)
      await orderRef.update({
        "payment.stripePaymentIntentId": paymentIntent.id,
        "payment.status": "created",
        updatedAt: new Date(),
      });

      return {
        clientSecret: paymentIntent.client_secret!,
        ephemeralKey: ephemeralKey.secret!,
        customerId: stripeCustomerId,
        publishableKey: stripePublishableKey.value(),
      };
    }
  );
