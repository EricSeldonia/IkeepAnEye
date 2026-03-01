import SwiftUI
import SDWebImageSwiftUI

struct CatalogGridView: View {
    @StateObject private var viewModel = CatalogGridViewModel()
    @EnvironmentObject private var cartStore: CartStore
    @State private var showCart = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.products.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.products.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Products")
                        .font(.headline)
                    Text("Check back soon for new designs.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.products) { product in
                            NavigationLink(destination: ProductDetailView(product: product)) {
                                ProductCard(product: product)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Shop")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showCart = true } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "cart")
                            .font(.title2)
                        if cartStore.itemCount > 0 {
                            Text("\(cartStore.itemCount)")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 10, y: -10)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showCart) {
            NavigationStack {
                CartView()
            }
        }
        .onAppear {
            viewModel.onAppear()
            AnalyticsService.shared.track("catalog_viewed")
        }
    }
}

private struct ProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WebImage(url: URL(string: product.mainImageURL ?? ""))
                .resizable()
                .placeholder {
                    Rectangle()
                        .fill(Color(.secondarySystemBackground))
                        .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                }
                .scaledToFill()
                .frame(height: 160)
                .clipped()
                .cornerRadius(8)

            Text(product.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .foregroundColor(.primary)

            Text(product.formattedPrice)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .cardStyle()
        .padding(8)
    }
}
