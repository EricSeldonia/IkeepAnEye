import { useState, useEffect } from "react";
import {
  collection,
  onSnapshot,
  query,
  orderBy,
  doc,
  updateDoc,
  addDoc,
  serverTimestamp,
} from "firebase/firestore";
import { db } from "../firebase";
import { Product } from "../types";

export function useProducts() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(collection(db, "products"), orderBy("sortOrder", "asc"));
    const unsub = onSnapshot(q, (snapshot) => {
      setProducts(
        snapshot.docs.map((d) => ({ id: d.id, ...d.data() } as Product))
      );
      setLoading(false);
    });
    return unsub;
  }, []);

  async function toggleActive(productId: string, current: boolean) {
    await updateDoc(doc(db, "products", productId), {
      isActive: !current,
      updatedAt: serverTimestamp(),
    });
  }

  async function updateProduct(
    productId: string,
    fields: Partial<Omit<Product, "id">>
  ) {
    await updateDoc(doc(db, "products", productId), {
      ...fields,
      updatedAt: serverTimestamp(),
    });
  }

  async function addProduct(fields: Omit<Product, "id">): Promise<string> {
    const docRef = await addDoc(collection(db, "products"), {
      ...fields,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    return docRef.id;
  }

  return { products, loading, toggleActive, updateProduct, addProduct };
}
