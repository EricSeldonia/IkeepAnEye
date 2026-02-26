import Foundation

@MainActor
final class CartViewModel: ObservableObject {
    let product: Product
    let irisPhoto: IrisPhoto
    let compositeImage: UIImage?

    @Published var shipping: Address?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var createdOrder: Order?

    init(product: Product, irisPhoto: IrisPhoto, compositeImage: UIImage?) {
        self.product = product
        self.irisPhoto = irisPhoto
        self.compositeImage = compositeImage
    }

    var canProceed: Bool { shipping != nil }

    var subtotal: Int  { product.priceInCents }
    var shippingCost: Int { 999 }
    var tax: Int       { Int(Double(subtotal) * 0.08) }
    var total: Int     { subtotal + shippingCost + tax }

    func placeOrder() async {
        guard let shipping else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let order = try await OrderService.shared.createOrder(
                product: product,
                irisPhoto: irisPhoto,
                shipping: shipping,
                previewStoragePath: nil
            )
            createdOrder = order
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
