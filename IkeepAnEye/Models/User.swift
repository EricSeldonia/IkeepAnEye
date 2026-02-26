import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    var email: String
    var displayName: String?
    // stripeCustomerId is written by Cloud Function only — not set by client
    var stripeCustomerId: String?
    var defaultShipping: Address?
    var createdAt: Timestamp
    var lastSignInAt: Timestamp

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case stripeCustomerId
        case defaultShipping
        case createdAt
        case lastSignInAt
    }
}
