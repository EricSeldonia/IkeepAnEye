/**
 * One-time script: creates the first admin user in the admins/{uid} collection.
 *
 * Usage:
 *   # Local emulator (firebase emulators:start must be running):
 *   USE_EMULATOR=1 npx ts-node functions/src/scripts/createAdmin.ts admin@youremail.com
 *
 *   # Production (requires a service account JSON):
 *   GOOGLE_APPLICATION_CREDENTIALS=path/to/serviceAccountKey.json \
 *     npx ts-node functions/src/scripts/createAdmin.ts admin@youremail.com
 */

import * as admin from "firebase-admin";

const email = process.argv[2];
if (!email) {
  console.error("Usage: npx ts-node functions/src/scripts/createAdmin.ts <email>");
  process.exit(1);
}

if (process.env.USE_EMULATOR === "1") {
  process.env.FIRESTORE_EMULATOR_HOST = "localhost:8080";
  process.env.FIREBASE_AUTH_EMULATOR_HOST = "localhost:9099";
}

admin.initializeApp({ projectId: "ikeepaneye-4a2d8" });

async function main() {
  let userRecord: admin.auth.UserRecord;
  try {
    userRecord = await admin.auth().getUserByEmail(email);
    console.log(`Found existing Auth user: ${email} (uid: ${userRecord.uid})`);
  } catch {
    // User doesn't exist — create it (useful for emulator setup)
    const password = process.argv[3];
    if (!password) {
      console.error(`No Auth user found for ${email}.`);
      console.error(
        "Pass a password as the second argument to create them: createAdmin.ts <email> <password>"
      );
      process.exit(1);
    }
    userRecord = await admin.auth().createUser({ email, password });
    console.log(`Created Auth user: ${email} (uid: ${userRecord.uid})`);
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
