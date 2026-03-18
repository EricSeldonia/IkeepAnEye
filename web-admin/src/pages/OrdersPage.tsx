import { useState } from "react";
import { Link } from "react-router-dom";
import { useOrders } from "../hooks/useOrders";
import OrderStatusBadge from "../components/OrderStatusBadge";
import EyeThumb from "../components/EyeThumb";
import { OrderStatus } from "../types";

const TABS: { label: string; value: OrderStatus | "all" }[] = [
  { label: "All", value: "all" },
  { label: "Paid", value: "paid" },
  { label: "In Production", value: "in_production" },
  { label: "Shipped", value: "shipped" },
  { label: "Delivered", value: "delivered" },
  { label: "Refunded", value: "refunded" },
];

function fmt(cents: number) {
  return `$${(cents / 100).toFixed(2)}`;
}

type SortKey = "id" | "customer" | "total" | "status" | "date";
type SortDir = "asc" | "desc";

function SortIcon({ active, dir }: { active: boolean; dir: SortDir }) {
  return (
    <span className="ml-1 inline-block text-[10px] leading-none">
      {active ? (dir === "asc" ? "▲" : "▼") : <span className="text-gray-300">▲▼</span>}
    </span>
  );
}

export default function OrdersPage() {
  const { orders, loading } = useOrders();
  const [tab, setTab] = useState<OrderStatus | "all">("all");
  const [search, setSearch] = useState("");
  const [sortKey, setSortKey] = useState<SortKey>("date");
  const [sortDir, setSortDir] = useState<SortDir>("desc");

  function handleSort(key: SortKey) {
    if (sortKey === key) {
      setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    } else {
      setSortKey(key);
      setSortDir("asc");
    }
  }

  if (loading) return <p className="text-gray-500">Loading…</p>;

  const filtered = orders
    .filter((o) => tab === "all" || o.status === tab)
    .filter((o) => {
      if (!search) return true;
      const q = search.toLowerCase();
      return (
        o.id.toLowerCase().includes(q) ||
        o.productSnapshot?.name?.toLowerCase().includes(q) ||
        o.shipping?.name?.toLowerCase().includes(q)
      );
    })
    .slice()
    .sort((a, b) => {
      let cmp = 0;
      switch (sortKey) {
        case "id":
          cmp = a.id.localeCompare(b.id);
          break;
        case "customer":
          cmp = (a.shipping?.name ?? "").localeCompare(b.shipping?.name ?? "");
          break;
        case "total":
          cmp = (a.pricing?.totalCents ?? 0) - (b.pricing?.totalCents ?? 0);
          break;
        case "status":
          cmp = a.status.localeCompare(b.status);
          break;
        case "date":
          cmp = (a.createdAt?.seconds ?? 0) - (b.createdAt?.seconds ?? 0);
          break;
      }
      return sortDir === "asc" ? cmp : -cmp;
    });

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Orders</h1>

      {/* Tabs */}
      <div className="flex gap-1 mb-4 border-b border-gray-200">
        {TABS.map(({ label, value }) => (
          <button
            key={value}
            onClick={() => setTab(value)}
            className={`px-4 py-2 text-sm font-medium transition-colors border-b-2 -mb-px ${
              tab === value
                ? "border-blue-600 text-blue-600"
                : "border-transparent text-gray-500 hover:text-gray-700"
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      {/* Search */}
      <div className="mb-4">
        <input
          type="text"
          placeholder="Search by order ID, product, or customer name…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full max-w-md border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      <div className="bg-white rounded-xl shadow-sm">
        <table className="min-w-full divide-y divide-gray-100">
          <thead>
            <tr className="text-left text-xs text-gray-500 uppercase tracking-wide">
              {(
                [
                  { label: "Order ID", key: "id" },
                  { label: "Customer", key: "customer" },
                  { label: "Product", key: null },
                  { label: "Eye", key: null },
                  { label: "Total", key: "total" },
                  { label: "Status", key: "status" },
                  { label: "Date", key: "date" },
                ] as { label: string; key: SortKey | null }[]
              ).map(({ label, key }) =>
                key ? (
                  <th
                    key={label}
                    className="px-6 py-3 cursor-pointer select-none hover:text-gray-800"
                    onClick={() => handleSort(key)}
                  >
                    {label}
                    <SortIcon active={sortKey === key} dir={sortDir} />
                  </th>
                ) : (
                  <th key={label} className="px-6 py-3">
                    {label}
                  </th>
                )
              )}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {filtered.map((order) => (
              <tr key={order.id} className="hover:bg-gray-50">
                <td className="px-6 py-3 text-sm">
                  <Link
                    to={`/orders/${order.id}`}
                    className="text-blue-600 hover:underline font-mono"
                  >
                    {order.id.slice(0, 8)}…
                  </Link>
                </td>
                <td className="px-6 py-3 text-sm text-gray-700">
                  {order.shipping?.name ?? "—"}
                </td>
                <td className="px-6 py-3 text-sm text-gray-700">
                  <div className="flex items-center gap-2">
                    {order.productSnapshot?.imageURL && (
                      <img
                        src={order.productSnapshot.imageURL}
                        alt=""
                        className="w-10 h-10 rounded object-cover flex-shrink-0 ring-1 ring-gray-200"
                      />
                    )}
                    {order.productSnapshot?.name ?? "—"}
                  </div>
                </td>
                <td className="px-6 py-3">
                  {order.eyePhotoStoragePath
                    ? <EyeThumb storagePath={order.eyePhotoStoragePath} />
                    : <span className="text-sm text-gray-400">—</span>}
                </td>
                <td className="px-6 py-3 text-sm text-gray-700">
                  {fmt(order.pricing?.totalCents ?? 0)}
                </td>
                <td className="px-6 py-3">
                  <OrderStatusBadge status={order.status} />
                </td>
                <td className="px-6 py-3 text-sm text-gray-500">
                  {order.createdAt ? (
                    <>
                      <span>{order.createdAt.toDate().toLocaleDateString()}</span>
                      <br />
                      <span className="text-xs text-gray-400">
                        {order.createdAt.toDate().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
                      </span>
                    </>
                  ) : "—"}
                </td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr>
                <td
                  colSpan={7}
                  className="px-6 py-8 text-center text-sm text-gray-400"
                >
                  No orders found.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
