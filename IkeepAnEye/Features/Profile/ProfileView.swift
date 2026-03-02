import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var authService = AuthService.shared
    @State private var showDeleteConfirm = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(authService.currentUser?.displayName ?? "")
                            .font(.headline)
                        Text(authService.currentUser?.email ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Account") {
                NavigationLink("Manage Eye Photos") { ManageEyePhotosView() }
                NavigationLink("Shipping Addresses") { ShippingAddressView() }
            }

            Section("Privacy") {
                NavigationLink("Privacy Policy") {
                    PrivacyPolicyView()
                }
                Text("Eye photos are processed entirely on-device and never shared with third parties.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Button("Sign Out", role: .destructive) {
                    try? authService.signOut()
                }
            }

            Section {
                Button("Delete Account", role: .destructive) {
                    showDeleteConfirm = true
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .confirmationDialog(
            "Delete Account",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Account and All Data", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your account and all eye photos. This cannot be undone.")
        }
        .errorAlert(message: $errorMessage)
    }

    private func deleteAccount() async {
        do {
            try await authService.deleteAccount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("Privacy Policy\n\nIkeepAnEye processes eye photos entirely on your device using Apple's Vision framework. Photos are only uploaded to our secure cloud storage after you explicitly tap \"Use This Photo\". We never share your biometric data with third parties.\n\nYou may delete all your eye photos and account data at any time from the Profile tab.")
                .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}
