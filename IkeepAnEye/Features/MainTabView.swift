import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                CatalogGridView()
            }
            .tabItem {
                Label("Shop", systemImage: "sparkles")
            }
            .tag(0)

            NavigationStack {
                IrisCaptureContainerView()
            }
            .tabItem {
                Label("My Eye", systemImage: "eye.fill")
            }
            .tag(1)

            NavigationStack {
                OrderHistoryListView()
            }
            .tabItem {
                Label("Orders", systemImage: "shippingbox")
            }
            .tag(2)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle")
            }
            .tag(3)
        }
    }
}

/// Entry point for the IrisCapture tab.
struct IrisCaptureContainerView: View {
    @State private var showCapture = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            Text("Your Iris")
                .font(.title2.bold())
            Text("Photograph your eye to create a unique pendant.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Open Camera") {
                showCapture = true
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            Spacer()
        }
        .navigationTitle("Iris Capture")
        .fullScreenCover(isPresented: $showCapture) {
            CameraView(onCapture: { _ in
                showCapture = false
            })
        }
    }
}
