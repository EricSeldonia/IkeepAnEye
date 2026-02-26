import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Create Account")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)

                VStack(spacing: 16) {
                    TextField("Full Name", text: $viewModel.displayName)
                        .textContentType(.name)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)

                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)

                    SecureField("Password (min 8 characters)", text: $viewModel.password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                }

                Button("Create Account") {
                    Task { await viewModel.signUp() }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.isValid || viewModel.isLoading)

                HStack {
                    Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                    Text("or").foregroundColor(.secondary).font(.caption).fixedSize()
                    Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                }

                SignInWithAppleButton(.signUp) { request in
                    viewModel.prepareAppleRequest(request)
                } onCompletion: { result in
                    Task { await viewModel.handleAppleResult(result) }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(10)

                Text("By creating an account you agree to our Terms of Service and Privacy Policy.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
        }
        .loadingOverlay(viewModel.isLoading)
        .errorAlert(message: $viewModel.errorMessage)
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
final class SignUpViewModel: ObservableObject {
    @Published var displayName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService = AuthService.shared

    var isValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") &&
        password.count >= 8
    }

    func signUp() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.signUp(
                email: email,
                password: password,
                displayName: displayName.trimmingCharacters(in: .whitespaces)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let (req, _) = authService.startSIWARequest()
        request.requestedScopes = req.requestedScopes
        request.nonce = req.nonce
    }

    func handleAppleResult(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let auth):
            isLoading = true
            defer { isLoading = false }
            do {
                try await authService.completeSIWASignIn(with: auth)
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
            }
        }
    }
}
