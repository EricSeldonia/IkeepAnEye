import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

@MainActor
final class EyeUploadService: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var errorMessage: String?

    private let storage = Storage.storage()
    private let firestore = Firestore.firestore()

    /// Uploads original and cropped eye images, then creates a Firestore record.
    /// Returns the saved EyePhoto.
    func upload(original: UIImage, cropped: UIImage, confidence: Double) async throws -> EyePhoto {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw UploadError.notAuthenticated
        }
        isUploading = true
        uploadProgress = 0
        defer { isUploading = false }

        let photoId = UUID().uuidString
        let basePath = "users/\(uid)/eye/\(photoId)"
        let originalPath = "\(basePath)/original.jpg"
        let croppedPath  = "\(basePath)/cropped.jpg"

        guard let originalData = original.jpegData(compressionQuality: 0.85),
              let croppedData  = cropped.jpegData(compressionQuality: 0.9) else {
            throw UploadError.compressionFailed
        }

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Upload original (0–50% of progress)
        let originalRef = storage.reference().child(originalPath)
        _ = try await originalRef.putDataAsync(originalData, metadata: metadata) { [weak self] progress in
            guard let p = progress else { return }
            Task { @MainActor in self?.uploadProgress = p.fractionCompleted * 0.5 }
        }

        // Upload cropped (50–100% of progress)
        let croppedRef = storage.reference().child(croppedPath)
        _ = try await croppedRef.putDataAsync(croppedData, metadata: metadata) { [weak self] progress in
            guard let p = progress else { return }
            Task { @MainActor in self?.uploadProgress = 0.5 + p.fractionCompleted * 0.5 }
        }

        // Write Firestore record (client-writable per security rules)
        let eyePhoto = EyePhoto(
            originalStoragePath: originalPath,
            croppedStoragePath: croppedPath,
            capturedAt: .init(),
            isActive: true,
            metadata: .init(detectionConfidence: confidence)
        )
        let docRef = firestore
            .collection("users").document(uid)
            .collection("eyePhotos").document(photoId)
        try docRef.setData(from: eyePhoto)

        uploadProgress = 1.0
        return eyePhoto
    }
}

enum UploadError: LocalizedError {
    case notAuthenticated
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in to upload photos."
        case .compressionFailed: return "Could not compress the image for upload."
        }
    }
}
