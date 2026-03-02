import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class OrderService: ObservableObject {
    static let shared = OrderService()
    private init() {}

    private let db = Firestore.firestore()

    /// Creates a pending_payment order document in Firestore.
    /// Server-side price is always read from Firestore; never trust client price.
    func createOrder(
        product: Product,
        eyePhoto: EyePhoto?,
        shipping: Address,
        previewStoragePath: String?
    ) async throws -> Order {
        guard let uid = Auth.auth().currentUser?.uid,
              let productId = product.id else {
            throw OrderError.missingData
        }

        // Tax estimate (8% — server should recalculate authoritatively)
        let subtotal = product.priceInCents
        let shippingCents = 999
        let taxCents = Int(Double(subtotal) * 0.08)
        let total = subtotal + shippingCents + taxCents

        let order = Order(
            userId: uid,
            status: .pendingPayment,
            eyePhotoId: eyePhoto?.id,
            eyePhotoStoragePath: eyePhoto?.croppedStoragePath,
            productId: productId,
            productSnapshot: .init(
                name: product.name,
                priceInCents: product.priceInCents,
                imageURL: product.mainImageURL ?? ""
            ),
            previewCompositeStoragePath: previewStoragePath,
            shipping: shipping,
            pricing: .init(
                subtotalCents: subtotal,
                shippingCents: shippingCents,
                taxCents: taxCents,
                totalCents: total
            ),
            payment: nil,
            fulfillment: nil,
            createdAt: .init(),
            updatedAt: .init()
        )

        let ref = db.collection("orders").document()
        try ref.setData(from: order)
        var saved = order
        saved.id = ref.documentID
        return saved
    }

    func fetchOrders(for userId: String) async throws -> [Order] {
        let snapshot = try await db.collection("orders")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Order.self) }
    }

    func fetchOrder(id: String) async throws -> Order {
        let doc = try await db.collection("orders").document(id).getDocument()
        return try doc.data(as: Order.self)
    }
}

enum OrderError: LocalizedError {
    case missingData

    var errorDescription: String? {
        "Missing required order data. Please try again."
    }
}
