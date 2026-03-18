import Foundation
import FirebaseAuth
import FirebaseFirestore

enum AuthState: Equatable {
    case loading
    case unauthenticated
    case authenticated
}

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    private init() {
        setupAuthStateListener()
    }

    @Published var authState: AuthState = .loading
    @Published var currentUser: User?

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.currentUser = user
            self.authState = user != nil ? .authenticated : .unauthenticated
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Email/Password

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    // MARK: - Profile

    func updateDisplayName(_ name: String) async throws {
        guard let user = Auth.auth().currentUser else { throw AuthError.noCurrentUser }
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
        try await Firestore.firestore()
            .collection("users").document(user.uid)
            .setData(["displayName": name], merge: true)
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { throw AuthError.noCurrentUser }
        try await user.delete()
    }

}

enum AuthError: LocalizedError {
    case invalidCredential
    case noCurrentUser

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Invalid sign-in credential."
        case .noCurrentUser: return "No authenticated user found."
        }
    }
}
