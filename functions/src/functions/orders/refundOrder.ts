import * as functions from "firebase-functions";
import { db } from "../../config/firebase";
import { createStripe, stripeSecretKey } from "../../config/stripe";

interface RefundOrderRequest {
  orderId: string;
}

/**
 * Callable Cloud Function: issues a full Stripe refund for a paid order.
 *
 * Security:
 * - Verifies caller exists in /admins/{uid}
 * - Order must have a stripeChargeId (written by webhook on payment success)
 * - Updates order status to "refunded"
 */
export const refundOrder = functions
  .runWith({ secrets: [stripeSecretKey] })
  .https.onCall(
    async (data: RefundOrderRequest, context) => {
      // Auth check
      if (!context.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "Authentication required."
        );
      }

      // Admin check
      const adminSnap = await db
        .collection("admins")
        .doc(context.auth.uid)
        .get();
      if (!adminSnap.exists) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Admin access required."
        );
      }

      const { orderId } = data;
      if (!orderId || typeof orderId !== "string") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "orderId is required."
        );
      }

      // Load order
      const orderRef = db.collection("orders").doc(orderId);
      const orderSnap = await orderRef.get();
      if (!orderSnap.exists) {
        throw new functions.https.HttpsError("not-found", "Order not found.");
      }
      const order = orderSnap.data()!;

      // Validate refundable status
      const refundableStatuses = ["paid", "in_production"];
      if (!refundableStatuses.includes(order.status)) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          `Order status '${order.status}' is not refundable.`
        );
      }

      const chargeId = order.payment?.stripeChargeId;
      if (!chargeId) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "No Stripe charge ID found on this order."
        );
      }

      const stripe = createStripe(stripeSecretKey.value());

      // Create Stripe refund
      const refund = await stripe.refunds.create({ charge: chargeId });

      // Update order in Firestore
      await orderRef.update({
        status: "refunded",
        "payment.refundId": refund.id,
        "payment.refundedAt": new Date(),
        updatedAt: new Date(),
      });

      return { refundId: refund.id };
    }
  );
