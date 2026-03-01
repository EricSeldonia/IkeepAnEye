import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()

    let sessionId: String = UUID().uuidString

    private let db = Firestore.firestore()

    private init() {}

    func track(_ type: String, payload: [String: Any] = [:]) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("userEvents").addDocument(data: [
            "userId": uid,
            "type": type,
            "payload": payload,
            "sessionId": sessionId,
            "timestamp": Timestamp(date: Date()),
        ]) { _ in
            // Silently ignore errors — analytics must never crash the app
        }
    }
}
