import Foundation

@MainActor
final class CartStore: ObservableObject {
    @Published var items: [CartItem] = []

    var itemCount: Int { items.count }
    var totalCents: Int { items.reduce(0) { $0 + $1.product.priceInCents } }

    func add(_ item: CartItem) {
        items.append(item)
    }

    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    func clear() {
        items.removeAll()
    }
}
