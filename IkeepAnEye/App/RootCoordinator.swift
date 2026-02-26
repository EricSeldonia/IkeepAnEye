import SwiftUI
import FirebaseAuth

struct RootCoordinator: View {
    @StateObject private var authService = AuthService.shared

    var body: some View {
        Group {
            switch authService.authState {
            case .loading:
                SplashView()
            case .unauthenticated:
                NavigationStack {
                    LandingView()
                }
            case .authenticated:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.authState)
    }
}

private struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
                Text("IkeepAnEye")
                    .font(.largeTitle.bold())
            }
        }
    }
}
