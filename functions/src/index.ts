/**
 * Firebase Cloud Functions entry point.
 * All functions are exported here so Firebase CLI can discover them.
 */

// Auth triggers
export { createUserRecord } from "./functions/auth/createUserRecord";
export { deleteUserData }   from "./functions/auth/deleteUserData";

// Payment functions
export { createPaymentIntent }  from "./functions/payments/createPaymentIntent";
export { handleStripeWebhook }  from "./functions/payments/handleStripeWebhook";

// Order triggers
export { onOrderCreated }       from "./functions/orders/onOrderCreated";
export { onOrderStatusChanged } from "./functions/orders/onOrderStatusChanged";
export { refundOrder }          from "./functions/orders/refundOrder";

// Photo management
export { deleteEyePhoto } from "./functions/photos/deleteEyePhoto";
