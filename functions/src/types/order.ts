import { Address } from "./user";

export type OrderStatus =
  | "pending_payment"
  | "paid"
  | "in_production"
  | "shipped"
  | "delivered";

export interface Order {
  userId: string;
  status: OrderStatus;
  irisPhotoId: string;
  irisPhotoStoragePath: string;
  productId: string;
  productSnapshot: {
    name: string;
    priceInCents: number;
    imageURL: string;
  };
  previewCompositeStoragePath?: string;
  shipping: Address;
  pricing: {
    subtotalCents: number;
    shippingCents: number;
    taxCents: number;
    totalCents: number;
  };
  payment?: {
    stripePaymentIntentId: string;
    stripeChargeId?: string;
    status: string;
    paidAt?: FirebaseFirestore.Timestamp;
  };
  fulfillment?: {
    trackingNumber?: string;
    carrier?: string;
    shippedAt?: FirebaseFirestore.Timestamp;
  };
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}
