import { admin } from "../config/firebase";

export const notificationService = {
  /**
   * Sends a push notification to all FCM tokens registered for a user.
   * User document must have a `fcmTokens` array field for this to work.
   */
  async sendPushNotification(
    userId: string,
    title: string,
    body: string
  ): Promise<void> {
    try {
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      const tokens: string[] = userDoc.data()?.fcmTokens ?? [];
      if (tokens.length === 0) return;

      await admin.messaging().sendEachForMulticast({
        tokens,
        notification: { title, body },
        apns: {
          payload: { aps: { sound: "default", badge: 1 } },
        },
      });
    } catch (err) {
      console.error(`Failed to send push to user ${userId}:`, err);
    }
  },

  /**
   * Sends the "order paid" confirmation notification (called from webhook handler).
   */
  async sendOrderPaidConfirmation(orderId: string): Promise<void> {
    const snap = await admin.firestore().collection("orders").doc(orderId).get();
    if (!snap.exists) return;
    const order = snap.data()!;
    await notificationService.sendPushNotification(
      order.userId,
      "Payment confirmed!",
      "We've received your payment and will begin crafting your pendant."
    );
  },
};
