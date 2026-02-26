export interface AppUser {
  email: string;
  displayName?: string;
  stripeCustomerId?: string;
  defaultShipping?: Address;
  createdAt: FirebaseFirestore.Timestamp;
  lastSignInAt: FirebaseFirestore.Timestamp;
}

export interface Address {
  fullName: string;
  line1: string;
  line2?: string;
  city: string;
  state: string;
  postalCode: string;
  country: string;
}
