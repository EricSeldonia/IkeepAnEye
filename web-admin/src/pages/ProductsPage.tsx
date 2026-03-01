import { useState, useRef } from "react";
import { ref, uploadBytes, getDownloadURL, deleteObject } from "firebase/storage";
import { storage } from "../firebase";
import { useProducts } from "../hooks/useProducts";
import { Product, ProductImage } from "../types";

function fmt(cents: number) {
  return `$${(cents / 100).toFixed(2)}`;
}

function emptyForm(): Omit<Product, "id"> {
  return {
    name: "",
    description: "",
    priceInCents: 0,
    material: "",
    chainDetails: "",
    images: [],
    isActive: true,
    sortOrder: 0,
  };
}

export default function ProductsPage() {
  const { products, loading, toggleActive, updateProduct, addProduct } =
    useProducts();
  const [editing, setEditing] = useState<Product | null>(null);
  const [isAdding, setIsAdding] = useState(false);
  const [form, setForm] = useState<Omit<Product, "id">>(emptyForm());
  // productId is set once we know it (existing product or after addDoc)
  const [productId, setProductId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  function openEdit(product: Product) {
    setEditing(product);
    setProductId(product.id);
    setForm({ ...product });
    setIsAdding(false);
    setError(null);
  }

  function openAdd() {
    setEditing(null);
    setProductId(null);
    setForm(emptyForm());
    setIsAdding(true);
    setError(null);
  }

  function closeForm() {
    setEditing(null);
    setIsAdding(false);
    setProductId(null);
    setError(null);
  }

  async function handleSave() {
    setSaving(true);
    setError(null);
    try {
      if (isAdding) {
        const newId = await addProduct(form);
        // Expose the new ID so image uploads can work immediately
        setProductId(newId);
        setIsAdding(false);
        setEditing({ id: newId, ...form } as Product);
      } else if (editing) {
        await updateProduct(editing.id, form);
        closeForm();
      }
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Save failed.");
    } finally {
      setSaving(false);
    }
  }

  async function handleUpload(files: FileList | null) {
    if (!files || files.length === 0) return;

    const pid = productId;
    if (!pid) {
      setError("Save the product first, then upload images.");
      return;
    }

    setUploading(true);
    setError(null);
    try {
      const newImages: ProductImage[] = [...form.images];
      for (let i = 0; i < files.length; i++) {
        const file = files[i];
        const ext = file.name.split(".").pop() ?? "jpg";
        const filename = `${crypto.randomUUID()}.${ext}`;
        const storagePath = `products/${pid}/images/${filename}`;
        const storageRef = ref(storage, storagePath);
        await uploadBytes(storageRef, file, {
          contentType: file.type || "image/jpeg",
        });
        const downloadURL = await getDownloadURL(storageRef);
        newImages.push({
          storagePath,
          downloadURL,
          isMain: newImages.length === 0, // first uploaded image becomes main
        });
      }
      const updated = { ...form, images: newImages };
      setForm(updated);
      // Persist immediately
      await updateProduct(pid, { images: newImages });
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Upload failed.");
    } finally {
      setUploading(false);
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  }

  async function setMainImage(index: number) {
    const newImages = form.images.map((img, i) => ({
      ...img,
      isMain: i === index,
    }));
    setForm({ ...form, images: newImages });
    if (productId) {
      await updateProduct(productId, { images: newImages });
    }
  }

  async function deleteImage(index: number) {
    const img = form.images[index];
    const newImages = form.images
      .filter((_, i) => i !== index)
      .map((img, i) => ({
        ...img,
        // If we removed the main, promote the first remaining
        isMain: i === 0 ? true : img.isMain,
      }));
    // Fix: if original main was not removed, keep it
    const hadMain = form.images[index].isMain;
    if (!hadMain) {
      // Restore original isMain flags for remaining
      const origRemaining = form.images.filter((_, i) => i !== index);
      newImages.forEach((img, i) => {
        img.isMain = origRemaining[i].isMain;
      });
    }
    setForm({ ...form, images: newImages });
    try {
      await deleteObject(ref(storage, img.storagePath));
    } catch {
      // Ignore — object may not exist in emulator
    }
    if (productId) {
      await updateProduct(productId, { images: newImages });
    }
  }

  if (loading) return <p className="text-gray-500">Loading…</p>;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Products</h1>
        <button
          onClick={openAdd}
          className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors"
        >
          + Add Product
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-sm divide-y divide-gray-100">
        {products.map((product) => {
          const mainImg = product.images?.find((i) => i.isMain) ?? product.images?.[0];
          return (
            <div key={product.id} className="flex items-center gap-4 px-6 py-4">
              {mainImg && (
                <img
                  src={mainImg.downloadURL}
                  alt=""
                  className="w-12 h-12 rounded-lg object-cover bg-gray-100 flex-shrink-0"
                />
              )}
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="font-medium text-gray-900 truncate">
                    {product.name}
                  </span>
                  {!product.isActive && (
                    <span className="text-xs text-gray-400 bg-gray-100 px-2 py-0.5 rounded-full">
                      Inactive
                    </span>
                  )}
                </div>
                <p className="text-sm text-gray-500 truncate">
                  {product.description}
                </p>
              </div>
              <span className="text-sm font-medium text-gray-700 flex-shrink-0">
                {fmt(product.priceInCents)}
              </span>
              <div className="flex gap-2 flex-shrink-0">
                <button
                  onClick={() => toggleActive(product.id, product.isActive)}
                  className="px-3 py-1.5 text-xs rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 transition-colors"
                >
                  {product.isActive ? "Deactivate" : "Activate"}
                </button>
                <button
                  onClick={() => openEdit(product)}
                  className="px-3 py-1.5 text-xs rounded-lg border border-gray-200 text-gray-600 hover:bg-gray-50 transition-colors"
                >
                  Edit
                </button>
              </div>
            </div>
          );
        })}
        {products.length === 0 && (
          <p className="px-6 py-8 text-center text-sm text-gray-400">
            No products yet.
          </p>
        )}
      </div>

      {/* Edit / Add modal */}
      {(editing || isAdding) && (
        <div className="fixed inset-0 z-50 flex items-start justify-center bg-black/60 overflow-y-auto py-8">
          <div
            className="bg-white rounded-xl shadow-2xl p-6 max-w-lg w-full mx-4 my-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              {isAdding ? "Add Product" : "Edit Product"}
            </h3>

            {error && (
              <p className="mb-3 text-sm text-red-600">{error}</p>
            )}

            <div className="space-y-3">
              <Field label="Name">
                <input
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  className={inputCls}
                />
              </Field>
              <Field label="Description">
                <textarea
                  value={form.description}
                  onChange={(e) =>
                    setForm({ ...form, description: e.target.value })
                  }
                  rows={3}
                  className={inputCls}
                />
              </Field>
              <Field label="Price (cents)">
                <input
                  type="number"
                  min={0}
                  value={form.priceInCents}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      priceInCents: parseInt(e.target.value) || 0,
                    })
                  }
                  className={inputCls}
                />
              </Field>
              <Field label="Material">
                <input
                  value={form.material ?? ""}
                  onChange={(e) =>
                    setForm({ ...form, material: e.target.value })
                  }
                  className={inputCls}
                />
              </Field>
              <Field label="Chain Details">
                <input
                  value={form.chainDetails ?? ""}
                  onChange={(e) =>
                    setForm({ ...form, chainDetails: e.target.value })
                  }
                  className={inputCls}
                />
              </Field>
              <Field label="Sort Order">
                <input
                  type="number"
                  value={form.sortOrder}
                  onChange={(e) =>
                    setForm({
                      ...form,
                      sortOrder: parseInt(e.target.value) || 0,
                    })
                  }
                  className={inputCls}
                />
              </Field>
              <label className="flex items-center gap-2 text-sm text-gray-700">
                <input
                  type="checkbox"
                  checked={form.isActive}
                  onChange={(e) =>
                    setForm({ ...form, isActive: e.target.checked })
                  }
                  className="rounded"
                />
                Active (visible in app)
              </label>

              {/* Image gallery */}
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-2">
                  Images
                </label>
                {form.images.length > 0 && (
                  <div className="flex flex-wrap gap-2 mb-3">
                    {form.images.map((img, idx) => (
                      <div key={img.storagePath} className="relative group">
                        <img
                          src={img.downloadURL}
                          alt=""
                          className={`w-20 h-20 object-cover rounded-lg border-2 ${
                            img.isMain
                              ? "border-blue-500"
                              : "border-transparent"
                          }`}
                        />
                        {img.isMain && (
                          <span className="absolute bottom-0 left-0 right-0 text-center text-[10px] bg-blue-500 text-white rounded-b-lg py-0.5">
                            Main
                          </span>
                        )}
                        <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity rounded-lg flex flex-col items-center justify-center gap-1">
                          {!img.isMain && (
                            <button
                              onClick={() => setMainImage(idx)}
                              className="text-[10px] text-white bg-blue-600 px-1.5 py-0.5 rounded"
                            >
                              Set Main
                            </button>
                          )}
                          <button
                            onClick={() => deleteImage(idx)}
                            className="text-[10px] text-white bg-red-600 px-1.5 py-0.5 rounded"
                          >
                            Delete
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}

                {/* Upload button — only enabled once product exists (or editing) */}
                <div className="flex items-center gap-3">
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    multiple
                    className="hidden"
                    onChange={(e) => handleUpload(e.target.files)}
                    disabled={uploading || (!productId && isAdding)}
                  />
                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    disabled={uploading || (!productId && isAdding)}
                    className="px-3 py-1.5 text-xs rounded-lg border border-gray-300 text-gray-700 hover:bg-gray-50 disabled:opacity-40 transition-colors"
                  >
                    {uploading ? "Uploading…" : "Upload Images"}
                  </button>
                  {!productId && (
                    <span className="text-xs text-gray-400">
                      Save first to enable image upload.
                    </span>
                  )}
                </div>
              </div>
            </div>

            <div className="flex gap-3 justify-end mt-6">
              <button
                onClick={closeForm}
                className="px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleSave}
                disabled={saving}
                className="px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 transition-colors"
              >
                {saving ? "Saving…" : "Save"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

const inputCls =
  "w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500";

function Field({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <label className="block text-xs font-medium text-gray-600 mb-1">
        {label}
      </label>
      {children}
    </div>
  );
}
