import Foundation
import FirebaseFirestore

@MainActor
final class ProductService: ObservableObject {
    static let shared = ProductService()
    private init() {}

    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening() {
        guard listener == nil else { return }
        isLoading = true
        listener = db.collection("products")
            .whereField("isActive", isEqualTo: true)
            .order(by: "sortOrder")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoading = false
                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.products = (snapshot?.documents ?? []).compactMap {
                    try? $0.data(as: Product.self)
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func product(withId id: String) async throws -> Product {
        let doc = try await db.collection("products").document(id).getDocument()
        return try doc.data(as: Product.self)
    }
}
