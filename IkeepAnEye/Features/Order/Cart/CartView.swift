import SwiftUI

struct CartView: View {
    @EnvironmentObject private var cartStore: CartStore
    @StateObject private var viewModel = CartViewModel()
    @State private var showAddressSheet = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Items") {
                if cartStore.items.isEmpty {
                    Text("Your cart is empty")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(cartStore.items) { item in
                        CartItemRow(item: item)
                    }
                    .onDelete { cartStore.remove(at: $0) }
                }
            }

            Section("Shipping") {
                HStack {
                    Text("Address").font(.subheadline)
                    Spacer()
                    Button("Edit") { showAddressSheet = true }
                        .font(.subheadline)
                }
                if let address = viewModel.shipping {
                    Text(address.formatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Button("Add Address") { showAddressSheet = true }
                        .font(.subheadline)
                }
            }

            Section("Summary") {
                PricingRow(label: "Subtotal", cents: viewModel.subtotal(items: cartStore.items))
                PricingRow(label: "Shipping", cents: viewModel.shippingCost)
                PricingRow(label: "Tax (est.)", cents: viewModel.tax(items: cartStore.items))
                PricingRow(label: "Total", cents: viewModel.total(items: cartStore.items), bold: true)
            }
        }
        .onAppear {
            AnalyticsService.shared.track("cart_viewed", payload: [
                "itemCount": cartStore.itemCount,
            ])
        }
        .navigationTitle("Cart")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") { dismiss() }
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { viewModel.createdOrder != nil },
            set: { if !$0 { viewModel.createdOrder = nil } }
        )) {
            if let order = viewModel.createdOrder {
                CheckoutView(order: order)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button("Proceed to Payment") {
                Task { await viewModel.placeOrders(items: cartStore.items) }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.canProceed(items: cartStore.items) || viewModel.isLoading)
            .padding()
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $showAddressSheet) {
            AddressEntryView(address: $viewModel.shipping)
        }
        .loadingOverlay(viewModel.isLoading)
        .errorAlert(message: $viewModel.errorMessage)
    }
}

private struct CartItemRow: View {
    let item: CartItem

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: item.product.mainImageURL ?? "")) { phase in
                if case .success(let img) = phase { img.resizable().scaledToFill() }
                else { Color(.secondarySystemBackground) }
            }
            .frame(width: 56, height: 56)
            .cornerRadius(8)
            .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(item.product.name)
                    .font(.subheadline.weight(.medium))
                if item.eyePhoto != nil {
                    Text("Personalized")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            Spacer()
            Text(item.product.formattedPrice)
                .font(.subheadline)
        }
    }
}

private struct PricingRow: View {
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
