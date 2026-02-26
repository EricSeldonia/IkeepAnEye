import * as admin from "firebase-admin";

// Initialize once at module level
if (!admin.apps.length) {
  admin.initializeApp();
}

export const db = admin.firestore();
export const auth = admin.auth();
export const storage = admin.storage();
export { admin };
