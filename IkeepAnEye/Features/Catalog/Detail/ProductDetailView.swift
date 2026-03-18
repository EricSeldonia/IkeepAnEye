import SwiftUI
import SDWebImageSwiftUI
import FirebaseStorage
import FirebaseAuth

struct ProductDetailView: View {
    let product: Product
    @StateObject private var viewModel: ProductDetailViewModel
    @EnvironmentObject private var cartStore: CartStore
    @State private var showEyeCapture = false
    @State private var selectedImageIndex = 0
    @State private var selectedEyePhotoIds: Set<String> = []
    @State private var showAddedToast = false
    @State private var showSignInRequired = false

    private var selectedEyePhotos: [EyePhoto] {
        viewModel.eyePhotos.filter { photo in
            photo.id.map { selectedEyePhotoIds.contains($0) } ?? false
        }
    }

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
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 320)

                if product.images.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(product.images.enumerated()), id: \.offset) { idx, img in
                                Button { withAnimation { selectedImageIndex = idx } } label: {
                                    WebImage(url: URL(string: img.downloadURL))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 56, height: 56)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedImageIndex == idx ? Color("BrandRose") : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(product.name)
                        .font(.title2.bold())
                    Text(product.formattedPrice)
                        .font(.title3)
                        .foregroundColor(Color("BrandRose"))
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
                                // "None" option — clears all selections
                                Button { selectedEyePhotoIds.removeAll() } label: {
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
                                                selectedEyePhotoIds.isEmpty ? Color("BrandRose") : Color.clear,
                                                lineWidth: 3
                                            )
                                        )
                                        Text("None")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)

                                // Stored eye photos — tap to toggle selection
                                ForEach(viewModel.eyePhotos) { photo in
                                    Button {
                                        guard let pid = photo.id else { return }
                                        if selectedEyePhotoIds.contains(pid) {
                                            selectedEyePhotoIds.remove(pid)
                                        } else {
                                            selectedEyePhotoIds.insert(pid)
                                        }
                                    } label: {
                                        VStack(spacing: 4) {
                                            EyeThumbnailView(
                                                photo: photo,
                                                isSelected: photo.id.map { selectedEyePhotoIds.contains($0) } ?? false
                                            )
                                            Text("Eye")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }

                                // Snap new photo
                                Button { showEyeCapture = true } label: {
                                    VStack(spacing: 4) {
                                        ZStack {
                                            Ellipse()
                                                .fill(Color(.secondarySystemBackground))
                                                .frame(width: 80, height: 54)
                                            Image(systemName: "camera.fill")
                                                .foregroundColor(Color("BrandRose"))
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

                        if selectedEyePhotos.count == 1, let eye = selectedEyePhotos.first {
                            if Auth.auth().currentUser != nil {
                                NavigationLink(destination: PendantPreviewView(
                                    product: product,
                                    eyePhoto: eye
                                )) {
                                    Text("Preview Pendant")
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            } else {
                                Button("Preview Pendant") { showSignInRequired = true }
                                    .buttonStyle(SecondaryButtonStyle())
                            }
                        }

                        Button {
                            if Auth.auth().currentUser != nil {
                                if selectedEyePhotos.isEmpty {
                                    cartStore.add(CartItem(product: product, eyePhoto: nil))
                                } else {
                                    for photo in selectedEyePhotos {
                                        cartStore.add(CartItem(product: product, eyePhoto: photo))
                                    }
                                }
                                withAnimation { showAddedToast = true }
                                Task {
                                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                                    withAnimation { showAddedToast = false }
                                }
                            } else {
                                showSignInRequired = true
                            }
                        } label: {
                            let count = selectedEyePhotos.count
                            Text(count > 1 ? "Add \(count) to Cart" : "Add to Cart")
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
        .task { await viewModel.loadEyePhotos() }
        .fullScreenCover(isPresented: $showEyeCapture) {
            CameraView(onCapture: { eyePhoto in
                showEyeCapture = false
                viewModel.eyePhotos.insert(eyePhoto, at: 0)
                if let pid = eyePhoto.id { selectedEyePhotoIds.insert(pid) }
            })
        }
        .sheet(isPresented: $showSignInRequired) {
            NavigationStack { SignInView() }
        }
        .overlay(alignment: .bottom) {
            if showAddedToast {
                let count = max(selectedEyePhotos.count, 1)
                Text(count > 1 ? "\(count) items added to cart!" : "Added to cart!")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color("BrandRose"))
                    .cornerRadius(24)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .errorAlert(message: $viewModel.errorMessage)
    }
}

/// Loads and displays a single eye photo thumbnail from Firebase Storage.
private struct EyeThumbnailView: View {
    let photo: EyePhoto
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
            Ellipse().stroke(isSelected ? Color("BrandRose") : Color.clear, lineWidth: 3)
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
