import { Link } from "react-router-dom";
import { useCustomers } from "../hooks/useCustomers";

export default function CustomersPage() {
  const { customers, loading } = useCustomers();

  if (loading) return <p className="text-gray-500">Loading…</p>;

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Customers</h1>

      <div className="bg-white rounded-xl shadow-sm">
        <table className="min-w-full divide-y divide-gray-100">
          <thead>
            <tr className="text-left text-xs text-gray-500 uppercase tracking-wide">
              <th className="px-6 py-3">Email</th>
              <th className="px-6 py-3">Display Name</th>
              <th className="px-6 py-3">Orders</th>
              <th className="px-6 py-3">Joined</th>
              <th className="px-6 py-3"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {customers.map((c) => (
              <tr key={c.id} className="hover:bg-gray-50">
                <td className="px-6 py-3 text-sm text-gray-900">{c.email}</td>
                <td className="px-6 py-3 text-sm text-gray-700">
                  {c.displayName ?? "—"}
                </td>
                <td className="px-6 py-3 text-sm text-gray-700">
                  {c.orderCount}
                </td>
                <td className="px-6 py-3 text-sm text-gray-500">
                  {c.createdAt?.toDate().toLocaleDateString() ?? "—"}
                </td>
                <td className="px-6 py-3 text-sm">
                  <Link
                    to={`/customers/${c.id}`}
                    className="text-blue-600 hover:underline"
                  >
                    View
                  </Link>
                </td>
              </tr>
            ))}
            {customers.length === 0 && (
              <tr>
                <td
                  colSpan={4}
                  className="px-6 py-8 text-center text-sm text-gray-400"
                >
                  No customers yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
