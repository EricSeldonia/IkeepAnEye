import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class ProductDetailViewModel: ObservableObject {
    let product: Product

    @Published var eyePhotos: [EyePhoto] = []
    @Published var selectedEyePhoto: EyePhoto?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    init(product: Product) {
        self.product = product
    }

    func loadEyePhotos() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let snapshot = try await db
                .collection("users").document(uid)
                .collection("eyePhotos")
                .whereField("isActive", isEqualTo: true)
                .order(by: "capturedAt", descending: true)
                .getDocuments()
            eyePhotos = snapshot.documents.compactMap { try? $0.data(as: EyePhoto.self) }
            selectedEyePhoto = eyePhotos.first
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
