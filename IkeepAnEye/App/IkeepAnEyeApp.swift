import SwiftUI
import FirebaseCore

@main
struct IkeepAnEyeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootCoordinator()
        }
    }
}
