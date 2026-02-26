import SwiftUI
import SDWebImageSwiftUI

struct ProductDetailView: View {
    let product: Product
    @StateObject private var viewModel: ProductDetailViewModel
    @State private var showIrisCapture = false
    @State private var showCart = false
    @State private var selectedImageIndex = 0

    init(product: Product) {
        self.product = product
        _viewModel = StateObject(wrappedValue: ProductDetailViewModel(product: product))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Product image carousel
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(product.imageURLs.enumerated()), id: \.offset) { idx, url in
                        WebImage(url: URL(string: url))
                            .resizable()
                            .scaledToFill()
                            .clipped()
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 320)

                VStack(alignment: .leading, spacing: 12) {
                    Text(product.name)
                        .font(.title2.bold())
                    Text(product.formattedPrice)
                        .font(.title3)
                        .foregroundColor(.accentColor)
                    Text("Material: \(product.material)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Chain: \(product.chain.length) · \(product.chain.style)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Divider()

                    Text(product.description)
                        .font(.body)

                    Divider()

                    // Iris photo selector / preview
                    if viewModel.irisPhotos.isEmpty {
                        VStack(spacing: 12) {
                            Text("Add your iris photo to preview this pendant")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Button("Capture My Eye") { showIrisCapture = true }
                                .buttonStyle(SecondaryButtonStyle())
                        }
                    } else {
                        if let iris = viewModel.selectedIrisPhoto {
                            NavigationLink(destination: PendantPreviewView(
                                product: product,
                                irisPhoto: iris
                            )) {
                                Text("Preview Pendant")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadIrisPhotos() }
        .fullScreenCover(isPresented: $showIrisCapture) {
            CameraView(onCapture: { _ in
                showIrisCapture = false
                Task { await viewModel.loadIrisPhotos() }
            })
        }
        .errorAlert(message: $viewModel.errorMessage)
    }
}
