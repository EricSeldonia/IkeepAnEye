import { useEffect, useState } from "react";
import { getDownloadURL, ref } from "firebase/storage";
import { storage } from "../firebase";
import EyePhotoModal from "./EyePhotoModal";

export default function EyeThumb({ storagePath }: { storagePath: string }) {
  const [url, setUrl] = useState<string | null>(null);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    getDownloadURL(ref(storage, storagePath)).then(setUrl).catch(() => {});
  }, [storagePath]);

  if (!url) return <div className="w-10 h-10 rounded bg-gray-100 animate-pulse" />;

  return (
    <>
      <img
        src={url}
        alt="Eye"
        onClick={() => setOpen(true)}
        className="w-10 h-10 rounded object-cover cursor-pointer hover:opacity-80 ring-1 ring-gray-200"
      />
      {open && <EyePhotoModal storagePath={storagePath} onClose={() => setOpen(false)} />}
    </>
  );
}
