import SwiftUI

struct SignInView: View {
    @StateObject private var viewModel = SignInViewModel()

    var body: some View {
        ZStack {
            Color("BrandCream").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Welcome back")
                        .font(.title.bold())
                        .foregroundColor(Color("BrandCharcoal"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 24)

                    VStack(spacing: 16) {
                        TextField("Email", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textContentType(.emailAddress)
                            .brandTextField()

                        SecureField("Password", text: $viewModel.password)
                            .textContentType(.password)
                            .brandTextField()
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
                    .foregroundColor(Color("BrandRose"))
                }
                .padding(.horizontal, 24)
            }
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
}
