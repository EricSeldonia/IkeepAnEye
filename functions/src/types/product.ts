export interface Product {
  name: string;
  description: string;
  priceInCents: number;
  imageURLs: string[];
  pendantAnchorX: number;
  pendantAnchorY: number;
  pendantDiameterFraction: number;
  material: string;
  chain: { length: string; style: string };
  isActive: boolean;
  sortOrder: number;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}
