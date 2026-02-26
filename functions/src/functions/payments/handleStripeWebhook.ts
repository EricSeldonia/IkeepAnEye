import * as functions from "firebase-functions";
import { db } from "../../config/firebase";
import {
  createStripe,
  stripeSecretKey,
  stripeWebhookSecret,
} from "../../config/stripe";
import { notificationService } from "../../services/notificationService";

/**
 * HTTP endpoint for Stripe webhooks.
 * Verifies signature before processing — rejects any unsigned events.
 *
 * Configure in Stripe Dashboard:
 *   Endpoint URL: https://<region>-<project>.cloudfunctions.net/handleStripeWebhook
 *   Events: payment_intent.succeeded, payment_intent.payment_failed
 */
export const handleStripeWebhook = functions
  .runWith({ secrets: [stripeSecretKey, stripeWebhookSecret] })
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const stripe = createStripe(stripeSecretKey.value());
    const sig = req.headers["stripe-signature"] as string;

    let event;
    try {
      // req.rawBody is available in Firebase Functions
      event = stripe.webhooks.constructEvent(
        (req as any).rawBody,
        sig,
        stripeWebhookSecret.value()
      );
    } catch (err: any) {
      console.error("Webhook signature verification failed:", err.message);
      res.status(400).send(`Webhook Error: ${err.message}`);
      return;
    }

    switch (event.type) {
      case "payment_intent.succeeded": {
        const pi = event.data.object as any;
        const orderId = pi.metadata?.orderId;
        if (orderId) {
          await db
            .collection("orders")
            .doc(orderId)
            .update({
              status: "paid",
              "payment.status": "succeeded",
              "payment.stripeChargeId": pi.latest_charge ?? null,
              "payment.paidAt": new Date(),
              updatedAt: new Date(),
            });
          await notificationService.sendOrderPaidConfirmation(orderId);
          console.log(`Order ${orderId} marked as paid`);
        }
        break;
      }

      case "payment_intent.payment_failed": {
        const pi = event.data.object as any;
        const orderId = pi.metadata?.orderId;
        if (orderId) {
          await db.collection("orders").doc(orderId).update({
            "payment.status": "failed",
            updatedAt: new Date(),
          });
          console.log(`Payment failed for order ${orderId}`);
        }
        break;
      }

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    res.json({ received: true });
  });
