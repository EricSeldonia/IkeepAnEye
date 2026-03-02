import { useEffect, useState } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import {
  doc,
  onSnapshot,
  updateDoc,
  serverTimestamp,
} from "firebase/firestore";
import { httpsCallable } from "firebase/functions";
import { db, functions } from "../firebase";
import { Order } from "../types";
import OrderStatusBadge from "../components/OrderStatusBadge";
import EyePhotoModal from "../components/EyePhotoModal";

function fmt(cents: number) {
  return `$${(cents / 100).toFixed(2)}`;
}

export default function OrderDetailPage() {
  const { orderId } = useParams<{ orderId: string }>();
  const navigate = useNavigate();
  const [order, setOrder] = useState<Order | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showEyeModal, setShowEyeModal] = useState(false);
  const [showRefundConfirm, setShowRefundConfirm] = useState(false);
  const [trackingNumber, setTrackingNumber] = useState("");
  const [carrier, setCarrier] = useState("");

  useEffect(() => {
    if (!orderId) return;
    const unsub = onSnapshot(doc(db, "orders", orderId), (snap) => {
      if (snap.exists()) {
        setOrder({ id: snap.id, ...snap.data() } as Order);
      }
      setLoading(false);
    });
    return unsub;
  }, [orderId]);

  async function markInProduction() {
    if (!orderId) return;
    setActionLoading(true);
    setError(null);
    try {
      await updateDoc(doc(db, "orders", orderId), {
        status: "in_production",
        updatedAt: serverTimestamp(),
      });
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Update failed.");
    } finally {
      setActionLoading(false);
    }
  }

  async function markShipped() {
    if (!orderId || !trackingNumber.trim()) {
      setError("Tracking number is required.");
      return;
    }
    setActionLoading(true);
    setError(null);
    try {
      await updateDoc(doc(db, "orders", orderId), {
        status: "shipped",
        "fulfillment.trackingNumber": trackingNumber.trim(),
        "fulfillment.carrier": carrier.trim(),
        "fulfillment.shippedAt": serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Update failed.");
    } finally {
      setActionLoading(false);
    }
  }

  async function markDelivered() {
    if (!orderId) return;
    setActionLoading(true);
    setError(null);
    try {
      await updateDoc(doc(db, "orders", orderId), {
        status: "delivered",
        updatedAt: serverTimestamp(),
      });
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Update failed.");
    } finally {
      setActionLoading(false);
    }
  }

  async function handleRefund() {
    if (!orderId) return;
    setActionLoading(true);
    setError(null);
    setShowRefundConfirm(false);
    try {
      const refundOrder = httpsCallable(functions, "refundOrder");
      await refundOrder({ orderId });
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Refund failed.");
    } finally {
      setActionLoading(false);
    }
  }

  if (loading) return <p className="text-gray-500">Loading…</p>;
  if (!order) return <p className="text-gray-500">Order not found.</p>;

  const canRefund = ["paid", "in_production"].includes(order.status);
  const eyePath = order.eyePhotoStoragePath;

  return (
    <div className="max-w-2xl">
      <div className="flex items-center gap-3 mb-6">
        <button
          onClick={() => navigate("/orders")}
          className="text-sm text-gray-500 hover:text-gray-800"
        >
          ← Orders
        </button>
        <span className="text-gray-300">/</span>
        <span className="font-mono text-sm text-gray-600">{order.id}</span>
      </div>

      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Order Detail</h1>
        <OrderStatusBadge status={order.status} />
      </div>

      {error && (
        <div className="mb-4 px-4 py-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">
          {error}
        </div>
      )}

      {/* Info grid */}
      <div className="bg-white rounded-xl shadow-sm p-6 space-y-4 mb-6">
        <Row label="Order ID" value={<span className="font-mono text-xs">{order.id}</span>} />
        <Row
          label="Date"
          value={order.createdAt?.toDate().toLocaleString() ?? "—"}
        />
        <Row
          label="Payment"
          value={order.payment?.status ?? "—"}
        />
        <Row
          label="Customer UID"
          value={
            <Link
              to={`/customers`}
              className="font-mono text-xs text-blue-600 hover:underline"
            >
              {order.userId}
            </Link>
          }
        />
      </div>

      {/* Product */}
      <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
        <h2 className="text-sm font-semibold text-gray-700 uppercase tracking-wide mb-3">
          Product
        </h2>
        <div className="flex gap-4 items-start">
          {order.productSnapshot?.imageURL && (
            <img
              src={order.productSnapshot.imageURL}
              alt=""
              className="w-16 h-16 rounded-lg object-cover bg-gray-100"
            />
          )}
          <div>
            <p className="font-medium text-gray-900">
              {order.productSnapshot?.name}
            </p>
            <p className="text-sm text-gray-500 mt-1">
              {fmt(order.productSnapshot?.priceInCents ?? 0)}
            </p>
          </div>
        </div>
        {eyePath && (
          <button
            onClick={() => setShowEyeModal(true)}
            className="mt-4 px-4 py-2 bg-gray-100 text-gray-800 rounded-lg text-sm font-medium hover:bg-gray-200 transition-colors"
          >
            View Eye Photo
          </button>
        )}
      </div>

      {/* Pricing */}
      <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
        <h2 className="text-sm font-semibold text-gray-700 uppercase tracking-wide mb-3">
          Pricing
        </h2>
        <div className="space-y-2 text-sm">
          <PriceRow label="Subtotal" cents={order.pricing?.subtotalCents} />
          <PriceRow label="Shipping" cents={order.pricing?.shippingCents} />
          <PriceRow label="Tax" cents={order.pricing?.taxCents} />
          <div className="border-t border-gray-100 pt-2 font-semibold">
            <PriceRow label="Total" cents={order.pricing?.totalCents} />
          </div>
        </div>
      </div>

      {/* Shipping */}
      <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
        <h2 className="text-sm font-semibold text-gray-700 uppercase tracking-wide mb-3">
          Shipping Address
        </h2>
        <address className="not-italic text-sm text-gray-700 leading-relaxed">
          {order.shipping?.name}<br />
          {order.shipping?.line1}<br />
          {order.shipping?.line2 && <>{order.shipping.line2}<br /></>}
          {order.shipping?.city}, {order.shipping?.state}{" "}
          {order.shipping?.postalCode}<br />
          {order.shipping?.country}
        </address>
      </div>

      {/* Fulfillment */}
      {order.fulfillment?.trackingNumber && (
        <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
          <h2 className="text-sm font-semibold text-gray-700 uppercase tracking-wide mb-3">
            Fulfillment
          </h2>
          <Row label="Carrier" value={order.fulfillment.carrier ?? "—"} />
          <Row label="Tracking #" value={order.fulfillment.trackingNumber} />
          {order.fulfillment.shippedAt && (
            <Row
              label="Shipped At"
              value={order.fulfillment.shippedAt.toDate().toLocaleString()}
            />
          )}
        </div>
      )}

      {/* Status actions */}
      {order.status !== "refunded" &&
        order.status !== "cancelled" &&
        order.status !== "delivered" && (
          <div className="bg-white rounded-xl shadow-sm p-6 mb-6 space-y-4">
            <h2 className="text-sm font-semibold text-gray-700 uppercase tracking-wide">
              Actions
            </h2>

            {order.status === "paid" && (
              <button
                onClick={markInProduction}
                disabled={actionLoading}
                className="px-5 py-2 bg-purple-600 text-white rounded-lg text-sm font-medium hover:bg-purple-700 disabled:opacity-50 transition-colors"
              >
                Mark In Production
              </button>
            )}

            {order.status === "in_production" && (
              <div className="space-y-3">
                <div className="flex gap-3">
                  <input
                    type="text"
                    placeholder="Tracking number *"
                    value={trackingNumber}
                    onChange={(e) => setTrackingNumber(e.target.value)}
                    className="flex-1 border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <input
                    type="text"
                    placeholder="Carrier (e.g. USPS)"
                    value={carrier}
                    onChange={(e) => setCarrier(e.target.value)}
                    className="flex-1 border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <button
                  onClick={markShipped}
                  disabled={actionLoading}
                  className="px-5 py-2 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 disabled:opacity-50 transition-colors"
                >
                  Mark Shipped
                </button>
              </div>
            )}

            {order.status === "shipped" && (
              <button
                onClick={markDelivered}
                disabled={actionLoading}
                className="px-5 py-2 bg-green-600 text-white rounded-lg text-sm font-medium hover:bg-green-700 disabled:opacity-50 transition-colors"
              >
                Mark Delivered
              </button>
            )}

            {canRefund && (
              <div>
                <button
                  onClick={() => setShowRefundConfirm(true)}
                  disabled={actionLoading}
                  className="px-5 py-2 bg-red-600 text-white rounded-lg text-sm font-medium hover:bg-red-700 disabled:opacity-50 transition-colors"
                >
                  Refund &amp; Cancel
                </button>
              </div>
            )}
          </div>
        )}

      {/* Refund confirm dialog */}
      {showRefundConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
          <div className="bg-white rounded-xl shadow-2xl p-6 max-w-sm w-full mx-4">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              Confirm Refund
            </h3>
            <p className="text-sm text-gray-600 mb-5">
              This will issue a full Stripe refund and set the order status to{" "}
              <strong>refunded</strong>. This cannot be undone.
            </p>
            <div className="flex gap-3 justify-end">
              <button
                onClick={() => setShowRefundConfirm(false)}
                className="px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleRefund}
                className="px-4 py-2 text-sm bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
              >
                Refund
              </button>
            </div>
          </div>
        </div>
      )}

      {showEyeModal && eyePath && (
        <EyePhotoModal
          storagePath={eyePath}
          onClose={() => setShowEyeModal(false)}
        />
      )}
    </div>
  );
}

function Row({
  label,
  value,
}: {
  label: string;
  value: React.ReactNode;
}) {
  return (
    <div className="flex justify-between text-sm py-1">
      <span className="text-gray-500">{label}</span>
      <span className="text-gray-900">{value}</span>
    </div>
  );
}

function PriceRow({ label, cents }: { label: string; cents?: number }) {
  return (
    <div className="flex justify-between">
      <span className="text-gray-600">{label}</span>
      <span className="text-gray-900">{fmt(cents ?? 0)}</span>
    </div>
  );
}
