import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class CartViewModel: ObservableObject {
    @Published var shipping: Address?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var createdOrders: [Order] = []

    private let db = Firestore.firestore()

    init() {}

    func loadDefaultAddress() async {
        guard shipping == nil, let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let snap = try await db.collection("users").document(uid).getDocument()
            if let raw = snap.data()?["defaultShipping"] {
                let json = try JSONSerialization.data(withJSONObject: raw)
                shipping = try JSONDecoder().decode(Address.self, from: json)
            }
        } catch {
            // silently ignore — user can enter manually
        }
    }

    func canProceed(items: [CartItem]) -> Bool { shipping != nil && !items.isEmpty }

    func subtotal(items: [CartItem]) -> Int { items.reduce(0) { $0 + $1.product.priceInCents } }
    func shippingCost(itemCount: Int) -> Int { 999 * itemCount }
    func tax(items: [CartItem]) -> Int { Int(Double(subtotal(items: items)) * 0.08) }
    func total(items: [CartItem]) -> Int { subtotal(items: items) + shippingCost(itemCount: items.count) + tax(items: items) }

    func placeOrders(items: [CartItem]) async {
        guard let shipping, !items.isEmpty else { return }
        AnalyticsService.shared.track("checkout_started", payload: [
            "orderCount": items.count,
        ])
        isLoading = true
        defer { isLoading = false }
        do {
            var orders: [Order] = []
            for item in items {
                let order = try await OrderService.shared.createOrder(
                    product: item.product,
                    eyePhoto: item.eyePhoto,
                    shipping: shipping,
                    previewStoragePath: nil
                )
                orders.append(order)
            }
            createdOrders = orders
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
