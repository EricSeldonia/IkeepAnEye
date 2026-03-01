import { Timestamp } from "firebase/firestore";

export type OrderStatus =
  | "pending_payment"
  | "paid"
  | "in_production"
  | "shipped"
  | "delivered"
  | "cancelled"
  | "refunded";

export interface ProductSnapshot {
  name: string;
  priceInCents: number;
  imageURL: string;
}

export interface Pricing {
  subtotalCents: number;
  shippingCents: number;
  taxCents: number;
  totalCents: number;
}

export interface Address {
  name: string;
  line1: string;
  line2?: string;
  city: string;
  state: string;
  postalCode: string;
  country: string;
}

export interface PaymentInfo {
  stripePaymentIntentId: string;
  stripeChargeId?: string;
  status: string;
  paidAt?: Timestamp;
  refundId?: string;
  refundedAt?: Timestamp;
}

export interface FulfillmentInfo {
  trackingNumber?: string;
  carrier?: string;
  shippedAt?: Timestamp;
}

export interface Order {
  id: string;
  userId: string;
  status: OrderStatus;
  irisPhotoId?: string;
  irisPhotoStoragePath?: string;
  productId: string;
  productSnapshot: ProductSnapshot;
  shipping: Address;
  pricing: Pricing;
  payment?: PaymentInfo;
  fulfillment?: FulfillmentInfo;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface ProductImage {
  storagePath: string;
  downloadURL: string;
  isMain: boolean;
}

export interface Product {
  id: string;
  name: string;
  description: string;
  priceInCents: number;
  material?: string;
  chainDetails?: string;
  images: ProductImage[];
  isActive: boolean;
  sortOrder: number;
  createdAt?: Timestamp;
  updatedAt?: Timestamp;
}

export interface AppUser {
  id: string;
  email: string;
  displayName?: string;
  stripeCustomerId?: string;
  createdAt?: Timestamp;
  lastSignInAt?: Timestamp;
}

export interface IrisPhoto {
  id: string;
  originalStoragePath: string;
  croppedStoragePath: string;
  capturedAt: Timestamp;
  isActive: boolean;
}

export interface UserEvent {
  id: string;
  userId: string;
  type: string;
  payload: Record<string, unknown>;
  sessionId: string;
  timestamp: Timestamp;
}
