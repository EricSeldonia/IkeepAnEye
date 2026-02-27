import SwiftUI
import FirebaseCore

@main
struct IkeepAnEyeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var cartStore = CartStore()

    var body: some Scene {
        WindowGroup {
            RootCoordinator()
                .environmentObject(cartStore)
        }
    }
}
