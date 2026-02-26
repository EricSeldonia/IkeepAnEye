import SwiftUI

struct LandingView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.accentColor)
                Text("IkeepAnEye")
                    .font(.largeTitle.bold())
                Text("Wear your eye. Always close.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            VStack(spacing: 12) {
                NavigationLink(destination: SignUpView()) {
                    Text("Create Account")
                }
                .buttonStyle(PrimaryButtonStyle())

                NavigationLink(destination: SignInView()) {
                    Text("Sign In")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .navigationBarHidden(true)
    }
}
