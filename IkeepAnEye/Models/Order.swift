import Foundation
import FirebaseFirestore

struct Order: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var userId: String
    var status: OrderStatus
    var irisPhotoId: String?
    var irisPhotoStoragePath: String?
    var productId: String
    var productSnapshot: ProductSnapshot
    var previewCompositeStoragePath: String?
    var shipping: Address
    var pricing: Pricing
    // payment is written by Cloud Function only
    var payment: PaymentInfo?
    var fulfillment: FulfillmentInfo?
    var createdAt: Timestamp
    var updatedAt: Timestamp

    struct ProductSnapshot: Codable, Hashable {
        var name: String
        var priceInCents: Int
        var imageURL: String
    }

    struct Pricing: Codable, Hashable {
        var subtotalCents: Int
        var shippingCents: Int
        var taxCents: Int
        var totalCents: Int
    }

    // Written by Cloud Function only
    struct PaymentInfo: Codable, Hashable {
        var stripePaymentIntentId: String
        var stripeChargeId: String?
        var status: String
        var paidAt: Timestamp?
    }

    struct FulfillmentInfo: Codable, Hashable {
        var trackingNumber: String?
        var carrier: String?
        var shippedAt: Timestamp?
    }
}

enum OrderStatus: String, Codable, CaseIterable {
    case pendingPayment = "pending_payment"
    case paid
    case inProduction = "in_production"
    case shipped
    case delivered

    var displayName: String {
        switch self {
        case .pendingPayment: return "Pending Payment"
        case .paid: return "Payment Confirmed"
        case .inProduction: return "In Production"
        case .shipped: return "Shipped"
        case .delivered: return "Delivered"
        }
    }
}
