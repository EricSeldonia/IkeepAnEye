import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class ProductDetailViewModel: ObservableObject {
    let product: Product

    @Published var irisPhotos: [IrisPhoto] = []
    @Published var selectedIrisPhoto: IrisPhoto?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    init(product: Product) {
        self.product = product
    }

    func loadIrisPhotos() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let snapshot = try await db
                .collection("users").document(uid)
                .collection("irisPhotos")
                .whereField("isActive", isEqualTo: true)
                .order(by: "capturedAt", descending: true)
                .getDocuments()
            irisPhotos = snapshot.documents.compactMap { try? $0.data(as: IrisPhoto.self) }
            selectedIrisPhoto = irisPhotos.first
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
