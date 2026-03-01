import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ManageIrisPhotosView: View {
    @StateObject private var viewModel = ManageIrisPhotosViewModel()
    @State private var showCapture = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.photos.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.photos.isEmpty {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Iris Photos")
                            .font(.headline)
                        Text("Capture your first iris photo to get started.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    Button("Capture My Eye") { showCapture = true }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 40)
                }
            } else {
                List {
                    ForEach(viewModel.photos) { photo in
                        IrisPhotoRow(photo: photo)
                    }
                    .onDelete { indexSet in
                        Task { await viewModel.delete(at: indexSet) }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Iris Photos")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showCapture = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task { await viewModel.load() }
        .fullScreenCover(isPresented: $showCapture) {
            CameraView(onCapture: { _ in
                showCapture = false
                Task { await viewModel.load() }
            })
        }
        .errorAlert(message: $viewModel.errorMessage)
    }
}

@MainActor
final class ManageIrisPhotosViewModel: ObservableObject {
    @Published var photos: [IrisPhoto] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private let functionsClient = FunctionsClient()

    func load() async {
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
            photos = snapshot.documents.compactMap { try? $0.data(as: IrisPhoto.self) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(at indexSet: IndexSet) async {
        struct Request: Encodable { let photoId: String }
        struct Response: Decodable { let success: Bool }

        for index in indexSet {
            let photo = photos[index]
            guard let photoId = photo.id else { continue }
            do {
                let _: Response = try await functionsClient.call(
                    name: "deleteIrisPhoto",
                    data: Request(photoId: photoId)
                )
                photos.remove(at: index)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct IrisPhotoRow: View {
    let photo: IrisPhoto

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 36))
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text("Iris Photo")
                    .font(.headline)
                Text(photo.capturedAt.dateValue().formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "Detection confidence: %.0f%%", photo.metadata.detectionConfidence * 100))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
