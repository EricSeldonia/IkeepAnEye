import Foundation
import FirebaseFirestore

struct ProductImage: Codable, Hashable {
    var storagePath: String
    var downloadURL: String
    var isMain: Bool
}

struct Product: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var priceInCents: Int
    var images: [ProductImage]

    var mainImageURL: String? {
        images.first(where: { $0.isMain })?.downloadURL ?? images.first?.downloadURL
    }
    // Normalized (0–1) anchor position for pendant on the necklace photo
    var pendantAnchorX: Double
    var pendantAnchorY: Double
    // Fraction of necklace photo width for the pendant circle diameter
    var pendantDiameterFraction: Double
    var material: String
    var chain: ChainDetails
    var isActive: Bool
    var sortOrder: Int
    var createdAt: Timestamp
    var updatedAt: Timestamp

    var formattedPrice: String {
        let dollars = Double(priceInCents) / 100.0
        return String(format: "$%.2f", dollars)
    }
}

struct ChainDetails: Codable {
    var length: String   // e.g. "18 inches"
    var style: String    // e.g. "Cable", "Box", "Rolo"
}
