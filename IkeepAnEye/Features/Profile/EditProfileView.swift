import SwiftUI
import FirebaseAuth

struct EditProfileView: View {
    @StateObject private var authService = AuthService.shared
    @State private var displayName: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Display Name", text: $displayName)
                    .autocorrectionDisabled()
            }

            Section("Account") {
                HStack {
                    Text("Email")
                    Spacer()
                    Text(authService.currentUser?.email ?? "")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            }
        }
        .onAppear {
            displayName = authService.currentUser?.displayName ?? ""
        }
        .loadingOverlay(isLoading)
        .errorAlert(message: $errorMessage)
    }

    private func save() async {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await AuthService.shared.updateDisplayName(trimmed)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
