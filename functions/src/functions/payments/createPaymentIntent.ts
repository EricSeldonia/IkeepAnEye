import * as functions from "firebase-functions";
import { db } from "../../config/firebase";
import {
  createStripe,
  stripeSecretKey,
  stripePublishableKey,
} from "../../config/stripe";
import { Order } from "../../types/order";

interface CreatePaymentIntentRequest {
  orderIds: string[];
}

interface CreatePaymentIntentResponse {
  clientSecret: string;
  ephemeralKey: string;
  customerId: string;
  publishableKey: string;
}

/**
 * Callable Cloud Function: creates a single Stripe PaymentIntent for one or more orders.
 *
 * Security:
 * - Verifies the caller's Firebase Auth token
 * - Validates all orders belong to the caller
 * - Reads prices server-side from Firestore (never trusts client amounts)
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

      const { orderIds } = data;
      if (!Array.isArray(orderIds) || orderIds.length === 0) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "orderIds must be a non-empty array."
        );
      }

      // Load user's Stripe customer ID once
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

      // Process each order: validate + compute server-side pricing
      let combinedTotalCents = 0;
      const orderUpdates: Array<{ ref: FirebaseFirestore.DocumentReference; pricing: object }> = [];

      for (const orderId of orderIds) {
        const orderRef = db.collection("orders").doc(orderId);
        const orderSnap = await orderRef.get();
        if (!orderSnap.exists) {
          throw new functions.https.HttpsError("not-found", `Order ${orderId} not found.`);
        }
        const order = orderSnap.data() as Order;

        if (order.userId !== context.auth.uid) {
          throw new functions.https.HttpsError(
            "permission-denied",
            "You do not have permission to pay for this order."
          );
        }
        if (order.status !== "pending_payment") {
          throw new functions.https.HttpsError(
            "failed-precondition",
            `Order ${orderId} status is '${order.status}', not payable.`
          );
        }

        // Read authoritative price from Firestore product document
        const productSnap = await db.collection("products").doc(order.productId).get();
        if (!productSnap.exists) {
          throw new functions.https.HttpsError("not-found", `Product for order ${orderId} not found.`);
        }
        const serverPrice = productSnap.data()?.priceInCents as number;
        const shippingCents = 999;
        const taxCents = Math.round(serverPrice * 0.08);
        const totalCents = serverPrice + shippingCents + taxCents;

        combinedTotalCents += totalCents;
        orderUpdates.push({
          ref: orderRef,
          pricing: {
            "pricing.subtotalCents": serverPrice,
            "pricing.shippingCents": shippingCents,
            "pricing.taxCents": taxCents,
            "pricing.totalCents": totalCents,
          },
        });
      }

      // Create ephemeral key for PaymentSheet customer session
      const ephemeralKey = await stripe.ephemeralKeys.create(
        { customer: stripeCustomerId },
        { apiVersion: "2024-12-18.acacia" }
      );

      // Create single PaymentIntent for the combined total
      const paymentIntent = await stripe.paymentIntents.create({
        amount: combinedTotalCents,
        currency: "usd",
        customer: stripeCustomerId,
        metadata: {
          orderIds: JSON.stringify(orderIds),
          orderId: orderIds[0], // backward compat
          userId: context.auth.uid,
        },
        automatic_payment_methods: { enabled: true },
      });

      // Update all orders with server-computed pricing and payment intent ID
      const now = new Date();
      await Promise.all(
        orderUpdates.map(({ ref, pricing }) =>
          ref.update({
            ...pricing,
            "payment.stripePaymentIntentId": paymentIntent.id,
            "payment.status": "created",
            updatedAt: now,
          })
        )
      );

      return {
        clientSecret: paymentIntent.client_secret!,
        ephemeralKey: ephemeralKey.secret!,
        customerId: stripeCustomerId,
        publishableKey: stripePublishableKey.value(),
      };
    }
  );
