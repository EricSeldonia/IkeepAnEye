import Foundation
import StripePaymentSheet

/// Handles all Stripe interactions.
/// The client secret is obtained from a Cloud Function — never held server-side on the client.
@MainActor
final class StripeService: ObservableObject {
    static let shared = StripeService()
    private init() {}

    private let functionsClient = FunctionsClient()

    struct PaymentIntentResponse: Decodable {
        let clientSecret: String
        let ephemeralKey: String
        let customerId: String
        let publishableKey: String
    }

    /// Calls the `createPaymentIntent` Cloud Function and returns a configured PaymentSheet.
    func makePaymentSheet(for orderIds: [String]) async throws -> PaymentSheet {
        let response: PaymentIntentResponse = try await functionsClient.call(
            name: "createPaymentIntent",
            data: ["orderIds": orderIds]
        )

        // Set the publishable key before presenting PaymentSheet
        StripeAPI.defaultPublishableKey = response.publishableKey

        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "IkeepAnEye"
        config.customer = .init(id: response.customerId, ephemeralKeySecret: response.ephemeralKey)
        config.allowsDelayedPaymentMethods = false
        config.applePay = .init(merchantId: "merchant.com.ikeepaneye", merchantCountryCode: "US")

        return PaymentSheet(paymentIntentClientSecret: response.clientSecret, configuration: config)
    }
}
