import SwiftUI
import FirebaseStorage
import SDWebImageSwiftUI

struct OrderDetailView: View {
    let orderId: String
    @StateObject private var viewModel: OrderDetailViewModel
    @State private var showCheckout = false

    init(orderId: String) {
        self.orderId = orderId
        _viewModel = StateObject(wrappedValue: OrderDetailViewModel(orderId: orderId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.order == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.order == nil {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Could not load order")
                        .font(.headline)
                    Button("Retry") { Task { await viewModel.load() } }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let order = viewModel.order {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        // Product thumbnail + name + price
                        HStack(spacing: 12) {
                            WebImage(url: URL(string: order.productSnapshot.imageURL))
                                .resizable()
                                .placeholder { Color(.systemGray5) }
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(order.productSnapshot.name)
                                    .font(.headline)
                                Text(String(format: "$%.2f", Double(order.productSnapshot.priceInCents) / 100))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .cardStyle()

                        // Eye photo (if personalised)
                        if let eyePath = order.eyePhotoStoragePath {
                            EyePhotoSection(storagePath: eyePath)
                                .padding()
                                .cardStyle()
                        }

                        // Order ID · Date · Status
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Order ID").font(.caption).foregroundColor(.secondary)
                                Spacer()
                                Text(order.id.map { String($0.prefix(8)) + "…" } ?? "—")
                                    .font(.subheadline.monospaced())
                            }
                            HStack {
                                Text("Date").font(.caption).foregroundColor(.secondary)
                                Spacer()
                                Text(order.createdAt.dateValue()
                                    .formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                            }
                            HStack {
                                Text("Status").font(.caption).foregroundColor(.secondary)
                                Spacer()
                                StatusBadge(status: order.status)
                            }
                        }
                        .padding()
                        .cardStyle()

                        // Pricing breakdown
                        VStack(spacing: 8) {
                            PricingLine(label: "Subtotal", cents: order.pricing.subtotalCents)
                            PricingLine(label: "Shipping", cents: order.pricing.shippingCents)
                            PricingLine(label: "Tax",      cents: order.pricing.taxCents)
                            Divider()
                            PricingLine(label: "Total",    cents: order.pricing.totalCents, bold: true)
                        }
                        .padding()
                        .cardStyle()

                        // Shipping address
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ship to").font(.caption).foregroundColor(.secondary)
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

                        // Retry payment (pending_payment orders only)
                        if order.status == .pendingPayment {
                            Button {
                                showCheckout = true
                            } label: {
                                Label("Complete Payment", systemImage: "creditcard.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
                .navigationDestination(isPresented: $showCheckout) {
                    CheckoutView(orders: [order])
                }
            }
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onAppear {
            // Reload when returning from CheckoutView (e.g. after payment retry)
            guard viewModel.order != nil else { return }
            Task { await viewModel.load() }
        }
        .errorAlert(message: $viewModel.errorMessage)
    }
}

// MARK: - Eye photo card

private struct EyePhotoSection: View {
    let storagePath: String
    @State private var url: URL?
    @State private var failed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Eye Photo").font(.caption).foregroundColor(.secondary)

            Group {
                if let url {
                    WebImage(url: url)
                        .resizable()
                        .placeholder { Color(.systemGray5) }
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if failed {
                    Text("Photo unavailable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 60)
                } else {
                    Color(.systemGray5)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(ProgressView())
                }
            }
        }
        .task {
            do {
                url = try await Storage.storage()
                    .reference(withPath: storagePath)
                    .downloadURL()
            } catch {
                failed = true
            }
        }
    }
}

// MARK: - View model

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

// MARK: - Helpers

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
