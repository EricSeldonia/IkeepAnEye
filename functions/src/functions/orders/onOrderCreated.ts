import * as functions from "firebase-functions";
import { emailService } from "../../services/emailService";

/**
 * Triggered when a new order document is created.
 * Sends an order acknowledgement email.
 */
export const onOrderCreated = functions.firestore
  .document("orders/{orderId}")
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const orderId = context.params.orderId;

    if (order.status !== "pending_payment") return;

    try {
      await emailService.sendOrderAcknowledgement(orderId, order);
    } catch (err) {
      console.error("Failed to send order acknowledgement email:", err);
    }
  });
