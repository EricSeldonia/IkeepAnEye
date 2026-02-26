/**
 * Email service stub.
 * Replace with your email provider (SendGrid, Resend, etc.).
 * All methods log intent in development; wire up a real provider before launch.
 */
export const emailService = {
  async sendOrderAcknowledgement(orderId: string, order: any): Promise<void> {
    console.log(`[EMAIL] Order acknowledgement → ${order.userId} for order ${orderId}`);
    // TODO: integrate transactional email provider
  },

  async sendPaymentConfirmation(orderId: string, order: any): Promise<void> {
    console.log(`[EMAIL] Payment confirmation → ${order.userId} for order ${orderId}`);
  },

  async sendInProductionNotice(orderId: string, order: any): Promise<void> {
    console.log(`[EMAIL] In-production notice → ${order.userId} for order ${orderId}`);
  },

  async sendShippingConfirmation(orderId: string, order: any): Promise<void> {
    console.log(`[EMAIL] Shipping confirmation → ${order.userId} for order ${orderId}`);
    const tracking = order.fulfillment?.trackingNumber ?? "N/A";
    const carrier  = order.fulfillment?.carrier ?? "";
    console.log(`[EMAIL]   Tracking: ${carrier} ${tracking}`);
  },
};
