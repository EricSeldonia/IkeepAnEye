import SwiftUI

struct OrderDetailView: View {
    let orderId: String
    @StateObject private var viewModel: OrderDetailViewModel

    init(orderId: String) {
        self.orderId = orderId
        _viewModel = StateObject(wrappedValue: OrderDetailViewModel(orderId: orderId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let order = viewModel.order {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Status
                        HStack {
                            Text("Status")
                            Spacer()
                            StatusBadge(status: order.status)
                        }
                        .padding()
                        .cardStyle()

                        // Product
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Product").font(.caption).foregroundColor(.secondary)
                            Text(order.productSnapshot.name).font(.headline)
                            Text(String(format: "$%.2f", Double(order.productSnapshot.priceInCents) / 100))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .cardStyle()

                        // Pricing
                        VStack(spacing: 8) {
                            PricingLine(label: "Subtotal", cents: order.pricing.subtotalCents)
                            PricingLine(label: "Shipping", cents: order.pricing.shippingCents)
                            PricingLine(label: "Tax", cents: order.pricing.taxCents)
                            Divider()
                            PricingLine(label: "Total", cents: order.pricing.totalCents, bold: true)
                        }
                        .padding()
                        .cardStyle()

                        // Shipping
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Shipping to").font(.caption).foregroundColor(.secondary)
                            Text(order.shipping.formatted).font(.subheadline)
                        }
                        .padding()
                        .cardStyle()

                        // Tracking (if shipped)
                        if let tracking = order.fulfillment?.trackingNumber {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tracking").font(.caption).foregroundColor(.secondary)
                                Text(tracking).font(.subheadline)
                                if let carrier = order.fulfillment?.carrier {
                                    Text(carrier).font(.caption).foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .cardStyle()
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .errorAlert(message: $viewModel.errorMessage)
    }
}

@MainActor
final class OrderDetailViewModel: ObservableObject {
    let orderId: String
    @Published var order: Order?
    @Published var isLoading = false
    @Published var errorMessage: String?

    init(orderId: String) { self.orderId = orderId }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            order = try await OrderService.shared.fetchOrder(id: orderId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct PricingLine: View {
    let label: String
    let cents: Int
    var bold: Bool = false

    var body: some View {
        HStack {
            Text(label).font(bold ? .headline : .subheadline)
            Spacer()
            Text(String(format: "$%.2f", Double(cents) / 100))
                .font(bold ? .headline : .subheadline)
        }
    }
}
