/**
 * Seed script — populates the `products` Firestore collection with sample pendant data.
 *
 * Usage:
 *   # Production (requires a service account JSON):
 *   GOOGLE_APPLICATION_CREDENTIALS=path/to/sa.json \
 *     npx ts-node functions/src/scripts/seedProducts.ts
 *
 *   # Local emulator:
 *   USE_EMULATOR=1 npx ts-node functions/src/scripts/seedProducts.ts
 */

import * as admin from "firebase-admin";

// ─── Emulator detection ────────────────────────────────────────────────────

if (process.env.USE_EMULATOR === "1") {
  process.env.FIRESTORE_EMULATOR_HOST = "localhost:8080";
  console.log("🔧  Using local Firestore emulator at localhost:8080");
}

// ─── Firebase init ─────────────────────────────────────────────────────────

if (!admin.apps.length) {
  admin.initializeApp({ projectId: "ikeepaneye-4a2d8" });
}

const db = admin.firestore();

// ─── Product data ──────────────────────────────────────────────────────────

interface ProductImage {
  storagePath: string;
  downloadURL: string;
  isMain: boolean;
}

interface ProductSeed {
  id: string;
  name: string;
  description: string;
  priceInCents: number;
  images: ProductImage[];
  pendantAnchorX: number;
  pendantAnchorY: number;
  pendantDiameterFraction: number;
  material: string;
  chain: { length: string; style: string };
  isActive: boolean;
  sortOrder: number;
}

const products: ProductSeed[] = [
  {
    id: "classic-eye-pendant",
    name: "Classic Eye Pendant",
    description:
      "A timeless sterling silver pendant that captures the unique pattern of your eye in exquisite detail. Each piece is one-of-a-kind, just like you.",
    priceInCents: 12999,
    images: [
      {
        storagePath: "",
        downloadURL: "https://placehold.co/800x800/D4B896/FFFFFF?text=Classic+Iris+Pendant",
        isMain: true,
      },
    ],
    pendantAnchorX: 0.5,
    pendantAnchorY: 0.62,
    pendantDiameterFraction: 0.28,
    material: "Sterling Silver",
    chain: { length: "18\"", style: "Cable" },
    isActive: true,
    sortOrder: 1,
  },
  {
    id: "rose-gold-eye-locket",
    name: "Rose Gold Eye Locket",
    description:
      "An elegant rose gold plated locket with your eye artfully set inside. Opens to reveal a small keepsake compartment — wear your world close to your heart.",
    priceInCents: 15999,
    images: [
      {
        storagePath: "",
        downloadURL: "https://placehold.co/800x800/C9A0A0/FFFFFF?text=Rose+Gold+Iris+Locket",
        isMain: true,
      },
    ],
    pendantAnchorX: 0.5,
    pendantAnchorY: 0.58,
    pendantDiameterFraction: 0.24,
    material: "Rose Gold Plated",
    chain: { length: "20\"", style: "Box" },
    isActive: true,
    sortOrder: 2,
  },
  {
    id: "minimalist-eye-disc",
    name: "Minimalist Eye Disc",
    description:
      "Clean lines, modern aesthetic. This lightweight titanium disc lets your eye speak for itself with no embellishment — pure, personal, powerful.",
    priceInCents: 9999,
    images: [
      {
        storagePath: "",
        downloadURL: "https://placehold.co/800x800/B0BEC5/FFFFFF?text=Minimalist+Iris+Disc",
        isMain: true,
      },
    ],
    pendantAnchorX: 0.5,
    pendantAnchorY: 0.5,
    pendantDiameterFraction: 0.32,
    material: "Titanium",
    chain: { length: "16\"", style: "Rolo" },
    isActive: true,
    sortOrder: 3,
  },
];

// ─── Seed ──────────────────────────────────────────────────────────────────

async function seed(): Promise<void> {
  const now = admin.firestore.Timestamp.now();

  for (const { id, ...fields } of products) {
    const ref = db.collection("products").doc(id);
    try {
      await ref.set({
        ...fields,
        createdAt: now,
        updatedAt: now,
      });
      console.log(`✅  products/${id}`);
    } catch (err) {
      console.error(`❌  products/${id}:`, err);
    }
  }

  console.log("\nDone. Seeded", products.length, "products.");
}

seed().catch((err) => {
  console.error("Seed failed:", err);
  process.exit(1);
});
