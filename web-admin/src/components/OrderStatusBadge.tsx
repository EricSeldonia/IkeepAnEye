import { OrderStatus } from "../types";

const config: Record<OrderStatus, { label: string; className: string }> = {
  pending_payment: { label: "Pending Payment", className: "bg-yellow-100 text-yellow-800" },
  paid: { label: "Paid", className: "bg-blue-100 text-blue-800" },
  in_production: { label: "In Production", className: "bg-purple-100 text-purple-800" },
  shipped: { label: "Shipped", className: "bg-indigo-100 text-indigo-800" },
  delivered: { label: "Delivered", className: "bg-green-100 text-green-800" },
  cancelled: { label: "Cancelled", className: "bg-gray-100 text-gray-700" },
  refunded: { label: "Refunded", className: "bg-red-100 text-red-800" },
};

export default function OrderStatusBadge({ status }: { status: OrderStatus }) {
  const { label, className } = config[status] ?? {
    label: status,
    className: "bg-gray-100 text-gray-600",
  };
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${className}`}>
      {label}
    </span>
  );
}
