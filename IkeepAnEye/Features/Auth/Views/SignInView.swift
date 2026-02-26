import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @StateObject private var viewModel = SignInViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Welcome back")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)

                VStack(spacing: 16) {
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)

                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                }

                Button("Sign In") {
                    Task { await viewModel.signIn() }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.isLoading)

                Button("Forgot Password?") {
                    Task { await viewModel.sendPasswordReset() }
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)

                HStack {
                    Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                    Text("or").foregroundColor(.secondary).font(.caption).fixedSize()
                    Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                }

                SignInWithAppleButton(.signIn) { request in
                    viewModel.prepareAppleRequest(request)
                } onCompletion: { result in
                    Task { await viewModel.handleAppleResult(result) }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(10)
            }
            .padding(.horizontal, 24)
        }
        .loadingOverlay(viewModel.isLoading)
        .errorAlert(message: $viewModel.errorMessage)
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
final class SignInViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService = AuthService.shared

    func signIn() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendPasswordReset() async {
        guard !email.isEmpty else {
            errorMessage = "Enter your email address first."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.sendPasswordReset(email: email)
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
