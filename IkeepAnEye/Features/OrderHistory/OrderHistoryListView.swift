import SwiftUI
import FirebaseAuth

struct OrderHistoryListView: View {
    @StateObject private var viewModel = OrderHistoryViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.orders.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.orders.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Orders Yet")
                        .font(.headline)
                    Text("Your orders will appear here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.orders) { order in
                    NavigationLink(destination: OrderDetailView(orderId: order.id ?? "")) {
                        OrderRow(order: order)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .onAppear {
            AnalyticsService.shared.track("order_history_viewed")
        }
        .navigationTitle("Orders")
        .task { await viewModel.load() }
        .errorAlert(message: $viewModel.errorMessage)
    }
}

@MainActor
final class OrderHistoryViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            orders = try await OrderService.shared.fetchOrders(for: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct OrderRow: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(order.productSnapshot.name)
                    .font(.headline)
                Spacer()
                StatusBadge(status: order.status)
            }
            Text(String(format: "$%.2f", Double(order.pricing.totalCents) / 100))
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(order.createdAt.dateValue().formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: OrderStatus

    private var color: Color {
        switch status {
        case .pendingPayment: return .orange
        case .paid:           return .blue
        case .inProduction:   return .purple
        case .shipped:        return .green
        case .delivered:      return .green
        }
    }

    var body: some View {
        Text(status.displayName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}
