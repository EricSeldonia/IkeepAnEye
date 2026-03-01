import SwiftUI
import SDWebImageSwiftUI
import FirebaseStorage

struct ProductDetailView: View {
    let product: Product
    @StateObject private var viewModel: ProductDetailViewModel
    @EnvironmentObject private var cartStore: CartStore
    @State private var showIrisCapture = false
    @State private var selectedImageIndex = 0
    @State private var selectedIrisPhoto: IrisPhoto?
    @State private var showAddedToast = false

    init(product: Product) {
        self.product = product
        _viewModel = StateObject(wrappedValue: ProductDetailViewModel(product: product))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Product image carousel
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(product.images.enumerated()), id: \.offset) { idx, img in
                        WebImage(url: URL(string: img.downloadURL))
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

                    // Personalization section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Personalize your pendant")
                            .font(.headline)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // "None" option
                                Button { selectedIrisPhoto = nil } label: {
                                    VStack(spacing: 4) {
                                        ZStack {
                                            Ellipse()
                                                .fill(Color(.secondarySystemBackground))
                                                .frame(width: 80, height: 54)
                                            Image(systemName: "xmark")
                                                .foregroundColor(.secondary)
                                        }
                                        .overlay(
                                            Ellipse().stroke(
                                                selectedIrisPhoto == nil ? Color.accentColor : Color.clear,
                                                lineWidth: 3
                                            )
                                        )
                                        Text("None")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)

                                // Stored iris photos
                                ForEach(viewModel.irisPhotos) { photo in
                                    Button { selectedIrisPhoto = photo } label: {
                                        VStack(spacing: 4) {
                                            IrisThumbnailView(
                                                photo: photo,
                                                isSelected: selectedIrisPhoto?.id == photo.id
                                            )
                                            Text("Eye")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }

                                // Snap new photo
                                Button { showIrisCapture = true } label: {
                                    VStack(spacing: 4) {
                                        ZStack {
                                            Ellipse()
                                                .fill(Color(.secondarySystemBackground))
                                                .frame(width: 80, height: 54)
                                            Image(systemName: "camera.fill")
                                                .foregroundColor(.accentColor)
                                        }
                                        Text("New")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 2)
                            .padding(.vertical, 4)
                        }

                        if let iris = selectedIrisPhoto {
                            NavigationLink(destination: PendantPreviewView(
                                product: product,
                                irisPhoto: iris
                            )) {
                                Text("Preview Pendant")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }

                        Button {
                            cartStore.add(CartItem(product: product, irisPhoto: selectedIrisPhoto))
                            withAnimation { showAddedToast = true }
                            Task {
                                try? await Task.sleep(nanoseconds: 2_000_000_000)
                                withAnimation { showAddedToast = false }
                            }
                        } label: {
                            Text("Add to Cart")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AnalyticsService.shared.track("product_viewed", payload: [
                "productId": product.id ?? "",
                "productName": product.name,
            ])
        }
        .task { await viewModel.loadIrisPhotos() }
        .fullScreenCover(isPresented: $showIrisCapture) {
            CameraView(onCapture: { _ in
                showIrisCapture = false
                Task { await viewModel.loadIrisPhotos() }
            })
        }
        .overlay(alignment: .bottom) {
            if showAddedToast {
                Text("Added to cart!")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(24)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .errorAlert(message: $viewModel.errorMessage)
    }
}

/// Loads and displays a single iris photo thumbnail from Firebase Storage.
private struct IrisThumbnailView: View {
    let photo: IrisPhoto
    let isSelected: Bool

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Ellipse()
                    .fill(Color(.secondarySystemBackground))
                    .overlay(ProgressView().scaleEffect(0.6))
            }
        }
        .frame(width: 80, height: 54)
        .clipShape(Ellipse())
        .overlay(
            Ellipse().stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
        )
        .task { await loadImage() }
    }

    private func loadImage() async {
        let ref = Storage.storage().reference().child(photo.croppedStoragePath)
        if let data = try? await ref.data(maxSize: 5 * 1024 * 1024) {
            image = UIImage(data: data)
        }
    }
}
