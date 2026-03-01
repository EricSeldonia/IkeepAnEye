import { useState, useEffect } from "react";
import {
  collection,
  onSnapshot,
  query,
  orderBy,
  DocumentData,
  QuerySnapshot,
} from "firebase/firestore";
import { db } from "../firebase";
import { Order } from "../types";

function snapToOrder(snap: DocumentData, id: string): Order {
  return { id, ...(snap as Omit<Order, "id">) };
}

export function useOrders() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(collection(db, "orders"), orderBy("createdAt", "desc"));
    const unsub = onSnapshot(q, (snapshot: QuerySnapshot) => {
      setOrders(
        snapshot.docs.map((d) => snapToOrder(d.data(), d.id))
      );
      setLoading(false);
    });
    return unsub;
  }, []);

  return { orders, loading };
}
