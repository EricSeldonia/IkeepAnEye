import * as functions from "firebase-functions";
import { db, storage } from "../../config/firebase";

interface DeleteEyePhotoRequest {
  photoId: string;
}

/**
 * Callable CF: marks an eye photo inactive and deletes the Storage files.
 * Client update in Firestore only flips isActive=false; this CF does the cleanup.
 * Only the owning user can call this.
 */
export const deleteEyePhoto = functions.https.onCall(
  async (data: DeleteEyePhotoRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required."
      );
    }

    const { photoId } = data;
    if (!photoId || typeof photoId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "photoId is required."
      );
    }

    const uid = context.auth.uid;
    const photoRef = db
      .collection("users")
      .doc(uid)
      .collection("eyePhotos")
      .doc(photoId);

    const photoSnap = await photoRef.get();
    if (!photoSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Photo not found.");
    }

    const photo = photoSnap.data()!;
    const bucket = storage.bucket();

    // Delete Storage files
    const filesToDelete = [
      photo.originalStoragePath,
      photo.croppedStoragePath,
    ].filter(Boolean);

    await Promise.allSettled(
      filesToDelete.map((path: string) =>
        bucket.file(path).delete().catch((e: Error) =>
          console.warn(`Could not delete ${path}:`, e.message)
        )
      )
    );

    // Hard-delete the Firestore document
    await photoRef.delete();

    console.log(`Deleted eye photo ${photoId} for user ${uid}`);
    return { success: true };
  }
);
