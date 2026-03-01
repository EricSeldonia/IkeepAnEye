import Foundation

@MainActor
final class CartViewModel: ObservableObject {
    @Published var shipping: Address?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var createdOrder: Order?

    init() {}

    func canProceed(items: [CartItem]) -> Bool { shipping != nil && !items.isEmpty }

    func subtotal(items: [CartItem]) -> Int { items.reduce(0) { $0 + $1.product.priceInCents } }
    var shippingCost: Int { 999 }
    func tax(items: [CartItem]) -> Int { Int(Double(subtotal(items: items)) * 0.08) }
    func total(items: [CartItem]) -> Int { subtotal(items: items) + shippingCost + tax(items: items) }

    func placeOrders(items: [CartItem]) async {
        guard let shipping, !items.isEmpty else { return }
        AnalyticsService.shared.track("checkout_started", payload: [
            "orderCount": items.count,
        ])
        isLoading = true
        defer { isLoading = false }
        do {
            var firstOrder: Order?
            for item in items {
                let order = try await OrderService.shared.createOrder(
                    product: item.product,
                    irisPhoto: item.irisPhoto,
                    shipping: shipping,
                    previewStoragePath: nil
                )
                if firstOrder == nil { firstOrder = order }
            }
            createdOrder = firstOrder
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
