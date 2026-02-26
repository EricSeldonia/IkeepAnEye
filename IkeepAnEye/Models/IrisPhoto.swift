import Foundation
import FirebaseFirestore

struct IrisPhoto: Codable, Identifiable {
    @DocumentID var id: String?
    var originalStoragePath: String
    var croppedStoragePath: String
    var capturedAt: Timestamp
    var isActive: Bool
    var metadata: IrisMetadata

    struct IrisMetadata: Codable {
        var detectionConfidence: Double
    }
}
