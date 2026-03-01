/**
 * One-time script: creates the first admin user in the admins/{uid} collection.
 *
 * Run from the repo root using the functions/ node_modules (firebase-admin is there):
 *
 *   Production:
 *     GOOGLE_APPLICATION_CREDENTIALS=path/to/serviceAccountKey.json \
 *       ./functions/node_modules/.bin/ts-node \
 *       --project firestore-setup/tsconfig.json \
 *       firestore-setup/create-admin.ts admin@youremail.com
 *
 *   Local emulator (firebase emulators:start must be running):
 *     FIRESTORE_EMULATOR_HOST=localhost:8080 \
 *     FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 \
 *       ./functions/node_modules/.bin/ts-node \
 *       --project firestore-setup/tsconfig.json \
 *       firestore-setup/create-admin.ts admin@youremail.com
 */

import * as admin from "firebase-admin";

const email = process.argv[2];
if (!email) {
  console.error("Usage: npx ts-node firestore-setup/create-admin.ts <email>");
  process.exit(1);
}

admin.initializeApp();

async function main() {
  // Look up the user by email
  let userRecord: admin.auth.UserRecord;
  try {
    userRecord = await admin.auth().getUserByEmail(email);
  } catch (err: unknown) {
    console.error(`No Firebase Auth user found for email: ${email}`);
    console.error(
      "Create the user in Firebase Auth first (sign up via the iOS app or Firebase Console)."
    );
    process.exit(1);
  }

  const uid = userRecord.uid;
  const adminRef = admin.firestore().collection("admins").doc(uid);
  const existing = await adminRef.get();

  if (existing.exists) {
    console.log(`✓ ${email} (uid: ${uid}) is already an admin.`);
    process.exit(0);
  }

  await adminRef.set({
    email,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`✓ Admin record created for ${email} (uid: ${uid})`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
