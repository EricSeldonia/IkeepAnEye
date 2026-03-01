import { useState, useEffect } from "react";
import { collection, getDocs, query, orderBy } from "firebase/firestore";
import { db } from "../firebase";
import { AppUser, Order } from "../types";

export function useCustomers() {
  const [customers, setCustomers] = useState<
    (AppUser & { orderCount: number })[]
  >([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      const [usersSnap, ordersSnap] = await Promise.all([
        getDocs(query(collection(db, "users"), orderBy("createdAt", "desc"))),
        getDocs(collection(db, "orders")),
      ]);

      const orderCounts: Record<string, number> = {};
      ordersSnap.docs.forEach((d) => {
        const userId = (d.data() as Order).userId;
        orderCounts[userId] = (orderCounts[userId] ?? 0) + 1;
      });

      setCustomers(
        usersSnap.docs.map((d) => ({
          id: d.id,
          ...(d.data() as Omit<AppUser, "id">),
          orderCount: orderCounts[d.id] ?? 0,
        }))
      );
      setLoading(false);
    }
    load();
  }, []);

  return { customers, loading };
}
