import SwiftUI
import FirebaseStorage

struct PendantPreviewView: View {
    let product: Product
    let irisPhoto: IrisPhoto

    @EnvironmentObject private var cartStore: CartStore
    @Environment(\.dismiss) private var dismiss
    @State private var irisImage: UIImage?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var renderedComposite: UIImage?

    @MainActor
    private var compositeContent: some View {
        ZStack {
            // Layer 1: product necklace photo
            if let url = URL(string: product.mainImageURL ?? "") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit()
                    default:
                        Color(.secondarySystemBackground)
                    }
                }
            }

            // Layer 2: iris oval at anchor position (landscape 3:2)
            if let irisImage {
                GeometryReader { geo in
                    let w = geo.size.width  * product.pendantDiameterFraction
                    let h = w * (2.0 / 3.0)
                    Image(uiImage: irisImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: w, height: h)
                        .clipShape(Ellipse())
                        .position(
                            x: geo.size.width  * product.pendantAnchorX,
                            y: geo.size.height * product.pendantAnchorY
                        )
                }
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            compositeContent
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .loadingOverlay(isLoading)

            Spacer()

            VStack(spacing: 12) {
                Text(product.name)
                    .font(.title3.bold())
                Text(product.formattedPrice)
                    .foregroundColor(.accentColor)

                Button {
                    cartStore.add(CartItem(
                        product: product,
                        irisPhoto: irisPhoto,
                        compositeImage: renderedComposite
                    ))
                    dismiss()
                } label: {
                    Text("Add to Cart")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadIrisImage() }
        .errorAlert(message: $errorMessage)
    }

    private func loadIrisImage() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let ref = Storage.storage().reference().child(irisPhoto.croppedStoragePath)
            let data = try await ref.data(maxSize: 10 * 1024 * 1024)
            irisImage = UIImage(data: data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
