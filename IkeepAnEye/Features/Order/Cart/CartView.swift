import SwiftUI

struct CartView: View {
    let product: Product
    let irisPhoto: IrisPhoto
    let compositeImage: UIImage?

    @StateObject private var viewModel: CartViewModel
    @State private var showAddressSheet = false
    @State private var showCheckout = false

    init(product: Product, irisPhoto: IrisPhoto, compositeImage: UIImage?) {
        self.product = product
        self.irisPhoto = irisPhoto
        self.compositeImage = compositeImage
        _viewModel = StateObject(wrappedValue: CartViewModel(
            product: product,
            irisPhoto: irisPhoto,
            compositeImage: compositeImage
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Product summary
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: product.imageURLs.first ?? "")) { phase in
                        if case .success(let img) = phase { img.resizable().scaledToFill() }
                        else { Color(.secondarySystemBackground) }
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.name).font(.headline)
                        Text(product.material).font(.caption).foregroundColor(.secondary)
                        Text(product.chain.length + " " + product.chain.style)
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(product.formattedPrice).font(.headline)
                }
                .cardStyle()
                .padding(.horizontal)

                // Shipping address
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Shipping Address").font(.headline)
                        Spacer()
                        Button("Edit") { showAddressSheet = true }
                            .font(.subheadline)
                    }
                    if let address = viewModel.shipping {
                        Text(address.formatted)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Button("Add Address") { showAddressSheet = true }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding()
                .cardStyle()
                .padding(.horizontal)

                // Pricing summary
                VStack(spacing: 8) {
                    PricingRow(label: "Subtotal", cents: viewModel.subtotal)
                    PricingRow(label: "Shipping", cents: viewModel.shippingCost)
                    PricingRow(label: "Tax (est.)", cents: viewModel.tax)
                    Divider()
                    PricingRow(label: "Total", cents: viewModel.total, bold: true)
                }
                .padding()
                .cardStyle()
                .padding(.horizontal)

                Button("Proceed to Payment") {
                    Task { await viewModel.placeOrder() }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.canProceed || viewModel.isLoading)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Cart")
        .navigationDestination(item: $viewModel.createdOrder) { order in
            CheckoutView(order: order)
        }
        .sheet(isPresented: $showAddressSheet) {
            AddressEntryView(address: $viewModel.shipping)
        }
        .loadingOverlay(viewModel.isLoading)
        .errorAlert(message: $viewModel.errorMessage)
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
