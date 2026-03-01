import { Link } from "react-router-dom";
import { useOrders } from "../hooks/useOrders";
import OrderStatusBadge from "../components/OrderStatusBadge";
import { Order } from "../types";

function fmt(cents: number) {
  return `$${(cents / 100).toFixed(2)}`;
}

function StatCard({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="bg-white rounded-xl shadow-sm p-6">
      <p className="text-sm text-gray-500">{label}</p>
      <p className="text-2xl font-bold text-gray-900 mt-1">{value}</p>
    </div>
  );
}

export default function DashboardPage() {
  const { orders, loading } = useOrders();

  if (loading) return <p className="text-gray-500">Loading…</p>;

  const paidOrders = orders.filter((o) =>
    ["paid", "in_production", "shipped", "delivered"].includes(o.status)
  );
  const totalRevenue = paidOrders.reduce(
    (sum, o) => sum + (o.pricing?.totalCents ?? 0),
    0
  );
  const pendingFulfillment = orders.filter((o) =>
    ["paid", "in_production"].includes(o.status)
  ).length;
  const shippedCount = orders.filter((o) => o.status === "shipped").length;
  const deliveredCount = orders.filter((o) => o.status === "delivered").length;

  const recent = orders.slice(0, 10);

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Dashboard</h1>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <StatCard label="Total Revenue" value={fmt(totalRevenue)} />
        <StatCard label="Pending Fulfillment" value={pendingFulfillment} />
        <StatCard label="Shipped" value={shippedCount} />
        <StatCard label="Delivered" value={deliveredCount} />
      </div>

      <div className="bg-white rounded-xl shadow-sm">
        <div className="px-6 py-4 border-b border-gray-100">
          <h2 className="text-base font-semibold text-gray-800">Recent Orders</h2>
        </div>
        <table className="min-w-full divide-y divide-gray-100">
          <thead>
            <tr className="text-left text-xs text-gray-500 uppercase tracking-wide">
              <th className="px-6 py-3">Order ID</th>
              <th className="px-6 py-3">Product</th>
              <th className="px-6 py-3">Total</th>
              <th className="px-6 py-3">Status</th>
              <th className="px-6 py-3">Date</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {recent.map((order: Order) => (
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
                  {order.productSnapshot?.name ?? "—"}
                </td>
                <td className="px-6 py-3 text-sm text-gray-700">
                  {fmt(order.pricing?.totalCents ?? 0)}
                </td>
                <td className="px-6 py-3">
                  <OrderStatusBadge status={order.status} />
                </td>
                <td className="px-6 py-3 text-sm text-gray-500">
                  {order.createdAt?.toDate().toLocaleDateString() ?? "—"}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
