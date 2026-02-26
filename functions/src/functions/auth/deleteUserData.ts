import * as functions from "firebase-functions";
import { db, storage } from "../../config/firebase";

/**
 * GDPR deletion trigger: when a Firebase Auth user is deleted,
 * purge all iris photos from Storage and anonymize their orders.
 */
export const deleteUserData = functions.auth.user().onDelete(async (user) => {
  const uid = user.uid;
  const bucket = storage.bucket();

  // 1. Delete all iris photo files from Storage
  try {
    await bucket.deleteFiles({ prefix: `users/${uid}/iris/` });
    console.log(`Deleted Storage files for user ${uid}`);
  } catch (err) {
    console.error("Error deleting Storage files:", err);
  }

  // 2. Delete all irisPhotos subcollection documents
  const photosRef = db.collection("users").doc(uid).collection("irisPhotos");
  const photoSnap = await photosRef.get();
  const photoDeletes = photoSnap.docs.map((d) => d.ref.delete());
  await Promise.all(photoDeletes);

  // 3. Anonymize orders (remove PII, keep for fulfillment records)
  const ordersSnap = await db
    .collection("orders")
    .where("userId", "==", uid)
    .get();
  const orderUpdates = ordersSnap.docs.map((d) =>
    d.ref.update({
      userId: "DELETED",
      irisPhotoStoragePath: null,
      previewCompositeStoragePath: null,
    })
  );
  await Promise.all(orderUpdates);

  // 4. Delete user document
  await db.collection("users").doc(uid).delete();

  console.log(`Completed data deletion for user ${uid}`);
});
