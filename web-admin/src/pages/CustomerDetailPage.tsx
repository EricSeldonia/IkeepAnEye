import { useEffect, useState } from "react";
import { useParams, Link } from "react-router-dom";
import {
  doc,
  getDoc,
  collection,
  getDocs,
  query,
  where,
  orderBy,
} from "firebase/firestore";
import { ref, getDownloadURL } from "firebase/storage";
import { db, storage } from "../firebase";
import { AppUser, IrisPhoto, Order, UserEvent } from "../types";
import { useUserEvents } from "../hooks/useUserEvents";
import IrisPhotoModal from "../components/IrisPhotoModal";
import OrderStatusBadge from "../components/OrderStatusBadge";

function fmt(cents: number) {
  return `$${(cents / 100).toFixed(2)}`;
}

const EVENT_LABELS: Record<string, string> = {
  catalog_viewed: "Viewed catalog",
  product_viewed: "Viewed product",
  iris_capture_started: "Started iris capture",
  iris_capture_completed: "Completed iris capture",
  cart_viewed: "Viewed cart",
  checkout_started: "Started checkout",
  payment_completed: "Completed payment",
  order_history_viewed: "Viewed order history",
};

function eventLabel(type: string) {
  return EVENT_LABELS[type] ?? type;
}

function eventDetail(event: UserEvent) {
  const p = event.payload;
  if (event.type === "product_viewed" && p.productName) {
    return String(p.productName);
  }
  if (event.type === "cart_viewed" && p.itemCount != null) {
    return `${p.itemCount} item(s)`;
  }
  if (event.type === "checkout_started" && p.orderCount != null) {
    return `${p.orderCount} order(s)`;
  }
  if (event.type === "payment_completed" && Array.isArray(p.orderIds)) {
    return `Order IDs: ${(p.orderIds as string[]).join(", ")}`;
  }
  return null;
}

// Group events by sessionId in order of first appearance
function groupBySession(events: UserEvent[]) {
  const groups: { sessionId: string; events: UserEvent[] }[] = [];
  const seen = new Map<string, UserEvent[]>();
  // events are desc by timestamp; reverse to process oldest first within groups
  const reversed = [...events].reverse();
  for (const e of reversed) {
    if (!seen.has(e.sessionId)) {
      const arr: UserEvent[] = [];
      seen.set(e.sessionId, arr);
      groups.push({ sessionId: e.sessionId, events: arr });
    }
    seen.get(e.sessionId)!.push(e);
  }
  // Reverse groups so most recent session first
  return groups.reverse();
}

export default function CustomerDetailPage() {
  const { userId } = useParams<{ userId: string }>();
  const [user, setUser] = useState<AppUser | null>(null);
  const [irisPhotos, setIrisPhotos] = useState<IrisPhoto[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedIrisPath, setSelectedIrisPath] = useState<string | null>(null);
  const { events, loading: eventsLoading } = useUserEvents(userId ?? "");

  // Iris photo thumbnail URLs
  const [thumbURLs, setThumbURLs] = useState<Record<string, string>>({});

  useEffect(() => {
    if (!userId) return;
    async function load() {
      setLoading(true);
      const [userSnap, photosSnap, ordersSnap] = await Promise.all([
        getDoc(doc(db, "users", userId!)),
        getDocs(
          query(
            collection(db, "users", userId!, "irisPhotos"),
            orderBy("capturedAt", "desc")
          )
        ),
        getDocs(
          query(
            collection(db, "orders"),
            where("userId", "==", userId),
            orderBy("createdAt", "desc")
          )
        ),
      ]);

      if (userSnap.exists()) {
        setUser({ id: userSnap.id, ...userSnap.data() } as AppUser);
      }
      const photos = photosSnap.docs.map(
        (d) => ({ id: d.id, ...d.data() } as IrisPhoto)
      );
      setIrisPhotos(photos);
      setOrders(
        ordersSnap.docs.map((d) => ({ id: d.id, ...d.data() } as Order))
      );

      // Fetch thumbnail download URLs for iris photos
      const urlMap: Record<string, string> = {};
      await Promise.all(
        photos.map(async (p) => {
          try {
            urlMap[p.id] = await getDownloadURL(
              ref(storage, p.croppedStoragePath)
            );
          } catch {
            // ignore
          }
        })
      );
      setThumbURLs(urlMap);
      setLoading(false);
    }
    load();
  }, [userId]);

  if (loading) return <p className="text-gray-500">Loading…</p>;
  if (!user) return <p className="text-gray-500">User not found.</p>;

  const sessionGroups = groupBySession(events);

  return (
    <div className="max-w-3xl">
      {/* Breadcrumb */}
      <div className="flex items-center gap-2 mb-6 text-sm text-gray-500">
        <Link to="/customers" className="hover:text-gray-800">
          ← Customers
        </Link>
        <span className="text-gray-300">/</span>
        <span className="font-mono text-gray-600">{userId}</span>
      </div>

      <h1 className="text-2xl font-bold text-gray-900 mb-6">Customer Detail</h1>

      {/* Profile card */}
      <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
        <h2 className="text-sm font-semibold text-gray-700 uppercase tracking-wide mb-3">
          Profile
        </h2>
        <div className="space-y-2 text-sm">
          <Row label="Email" value={user.email} />
          <Row label="Display Name" value={user.displayName ?? "—"} />
          <Row
            label="Joined"
            value={user.createdAt?.toDate().toLocaleDateString() ?? "—"}
          />
          <Row label="Orders" value={String(orders.length)} />
        </div>
      </div>

      {/* Iris Photos */}
      <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
        <h2 className="text-sm font-semibold text-gray-700 uppercase tracking-wide mb-3">
          Iris Photos ({irisPhotos.length})
        </h2>
        {irisPhotos.length === 0 ? (
          <p className="text-sm text-gray-400">No iris photos.</p>
        ) : (
          <div className="flex flex-wrap gap-3">
            {irisPhotos.map((photo) => (
              <button
                key={photo.id}
                onClick={() => setSelectedIrisPath(photo.croppedStoragePath)}
                className="w-16 h-16 rounded-full overflow-hidden bg-gray-100 border-2 border-transparent hover:border-blue-500 transition-colors flex-shrink-0"
              >
                {thumbURLs[photo.id] ? (
                  <img
                    src={thumbURLs[photo.id]}
                    alt="Iris"
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-gray-300 text-xs">
                    …
                  </div>
                )}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Orders */}
      <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
        <h2 className="text-sm font-semibold text-gray-700 uppercase tracking-wide mb-3">
          Orders ({orders.length})
        </h2>
        {orders.length === 0 ? (
          <p className="text-sm text-gray-400">No orders.</p>
        ) : (
          <table className="min-w-full text-sm">
            <thead>
              <tr className="text-left text-xs text-gray-500 uppercase tracking-wide border-b border-gray-100">
                <th className="pb-2 pr-4">ID</th>
                <th className="pb-2 pr-4">Product</th>
                <th className="pb-2 pr-4">Total</th>
                <th className="pb-2 pr-4">Status</th>
                <th className="pb-2">Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {orders.map((order) => (
                <tr key={order.id} className="hover:bg-gray-50">
                  <td className="py-2 pr-4">
                    <Link
                      to={`/orders/${order.id}`}
                      className="font-mono text-xs text-blue-600 hover:underline"
                    >
                      {order.id.slice(0, 8).toUpperCase()}
                    </Link>
                  </td>
                  <td className="py-2 pr-4 text-gray-800">
                    {order.productSnapshot?.name}
                  </td>
                  <td className="py-2 pr-4 text-gray-700">
                    {fmt(order.pricing?.totalCents ?? 0)}
                  </td>
                  <td className="py-2 pr-4">
                    <OrderStatusBadge status={order.status} />
                  </td>
                  <td className="py-2 text-gray-500">
                    {order.createdAt?.toDate().toLocaleDateString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Event Timeline */}
      <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
        <h2 className="text-sm font-semibold text-gray-700 uppercase tracking-wide mb-3">
          Activity Timeline
        </h2>
        {eventsLoading ? (
          <p className="text-sm text-gray-400">Loading events…</p>
        ) : sessionGroups.length === 0 ? (
          <p className="text-sm text-gray-400">No events recorded.</p>
        ) : (
          <div className="space-y-6">
            {sessionGroups.map((group) => {
              const firstEvent = group.events[0];
              const sessionDate = firstEvent.timestamp
                ?.toDate()
                .toLocaleString();
              return (
                <div key={group.sessionId}>
                  <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-2">
                    Session — {sessionDate}
                    <span className="font-mono ml-2 text-gray-300">
                      {group.sessionId.slice(0, 8)}
                    </span>
                  </p>
                  <div className="border-l-2 border-gray-100 ml-2 pl-4 space-y-2">
                    {group.events.map((event) => {
                      const detail = eventDetail(event);
                      return (
                        <div key={event.id} className="flex items-start gap-3">
                          <div className="w-1.5 h-1.5 rounded-full bg-blue-400 mt-1.5 flex-shrink-0 -ml-[1.3125rem]" />
                          <div className="min-w-0">
                            <span className="text-sm text-gray-800">
                              {eventLabel(event.type)}
                            </span>
                            {detail && (
                              <span className="ml-2 text-xs text-gray-500">
                                {detail}
                              </span>
                            )}
                            <span className="ml-2 text-xs text-gray-400">
                              {event.timestamp?.toDate().toLocaleTimeString()}
                            </span>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {selectedIrisPath && (
        <IrisPhotoModal
          storagePath={selectedIrisPath}
          onClose={() => setSelectedIrisPath(null)}
        />
      )}
    </div>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between py-1 border-b border-gray-50 last:border-0">
      <span className="text-gray-500">{label}</span>
      <span className="text-gray-900">{value}</span>
    </div>
  );
}
