import { storage } from "../config/firebase";

/**
 * Generates a short-lived signed URL for a Storage object.
 * Used to serve order preview composites without exposing Storage paths.
 * Expires in 1 hour.
 */
export async function getSignedUrl(storagePath: string): Promise<string> {
  const [url] = await storage
    .bucket()
    .file(storagePath)
    .getSignedUrl({
      action: "read",
      expires: Date.now() + 60 * 60 * 1000, // 1 hour
    });
  return url;
}
