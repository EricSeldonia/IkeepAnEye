import { useEffect, useState } from "react";
import { ref, getDownloadURL } from "firebase/storage";
import { storage } from "../firebase";

interface Props {
  storagePath: string;
  onClose: () => void;
}

export default function EyePhotoModal({ storagePath, onClose }: Props) {
  const [url, setUrl] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getDownloadURL(ref(storage, storagePath))
      .then(setUrl)
      .catch((e) => setError(e.message));
  }, [storagePath]);

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/70"
      onClick={onClose}
    >
      <div
        className="bg-white rounded-xl shadow-2xl p-6 max-w-lg w-full mx-4"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-gray-800">Eye Photo</h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 text-2xl leading-none"
          >
            &times;
          </button>
        </div>

        {error && (
          <p className="text-red-600 text-sm">{error}</p>
        )}
        {!url && !error && (
          <div className="flex items-center justify-center h-48 text-gray-400 text-sm">
            Loading…
          </div>
        )}
        {url && (
          <>
            <img
              src={url}
              alt="Eye"
              className="w-full rounded-lg object-contain max-h-80"
            />
            <div className="flex gap-3 mt-4">
              <a
                href={url}
                target="_blank"
                rel="noreferrer"
                className="flex-1 text-center px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors"
              >
                Print (open in new tab)
              </a>
              <a
                href={url}
                download="eye-photo.jpg"
                className="flex-1 text-center px-4 py-2 bg-gray-100 text-gray-800 rounded-lg text-sm font-medium hover:bg-gray-200 transition-colors"
              >
                Download
              </a>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
