import { useState, useEffect } from "react";
import {
  collection,
  query,
  where,
  orderBy,
  limit,
  getDocs,
} from "firebase/firestore";
import { db } from "../firebase";
import { UserEvent } from "../types";

export function useUserEvents(userId: string) {
  const [events, setEvents] = useState<UserEvent[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!userId) return;
    async function load() {
      setLoading(true);
      const q = query(
        collection(db, "userEvents"),
        where("userId", "==", userId),
        orderBy("timestamp", "desc"),
        limit(100)
      );
      const snap = await getDocs(q);
      setEvents(
        snap.docs.map((d) => ({ id: d.id, ...d.data() } as UserEvent))
      );
      setLoading(false);
    }
    load();
  }, [userId]);

  return { events, loading };
}
