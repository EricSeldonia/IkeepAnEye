import * as functions from "firebase-functions";
import { emailService } from "../../services/emailService";
import { notificationService } from "../../services/notificationService";

/**
 * Triggered when an order's status field changes.
 * Sends transactional emails and push notifications for key transitions.
 */
export const onOrderStatusChanged = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after  = change.after.data();
    const orderId = context.params.orderId;

    if (before.status === after.status) return;

    console.log(`Order ${orderId}: ${before.status} → ${after.status}`);

    switch (after.status as string) {
      case "paid":
        await emailService.sendPaymentConfirmation(orderId, after);
        break;

      case "in_production":
        await emailService.sendInProductionNotice(orderId, after);
        await notificationService.sendPushNotification(
          after.userId,
          "Your pendant is being crafted!",
          "We've started production on your pendant."
        );
        break;

      case "shipped":
        await emailService.sendShippingConfirmation(orderId, after);
        await notificationService.sendPushNotification(
          after.userId,
          "Your pendant has shipped!",
          `Tracking: ${after.fulfillment?.trackingNumber ?? "available soon"}`
        );
        break;

      case "delivered":
        await notificationService.sendPushNotification(
          after.userId,
          "Your pendant has arrived!",
          "We hope you love your pendant."
        );
        break;
    }
  });
