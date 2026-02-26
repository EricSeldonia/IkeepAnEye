import Foundation

// Transient model used in Cart before an Order document is created
struct OrderItem: Identifiable {
    var id = UUID()
    var product: Product
    var irisPhoto: IrisPhoto
    var shipping: Address?
}
