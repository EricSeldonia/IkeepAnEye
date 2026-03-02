import Foundation
import FirebaseFirestore

struct EyePhoto: Codable, Identifiable {
    @DocumentID var id: String?
    var originalStoragePath: String
    var croppedStoragePath: String
    var capturedAt: Timestamp
    var isActive: Bool
    var metadata: EyeMetadata

    struct EyeMetadata: Codable {
        var detectionConfidence: Double
    }
}
