import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var cartStore: CartStore
    @State private var selectedTab = 0
    @State private var showCart = false

    private var cartToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { showCart = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "cart")
                        .font(.title2)
                    if cartStore.itemCount > 0 {
                        Text("\(cartStore.itemCount)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color("BrandRose"))
                            .clipShape(Circle())
                            .offset(x: 10, y: -10)
                    }
                }
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                CatalogGridView()
                    .toolbar { cartToolbarItem }
            }
            .tabItem {
                Label("Shop", systemImage: "sparkles")
            }
            .tag(0)

            NavigationStack {
                EyeCaptureContainerView()
                    .toolbar { cartToolbarItem }
            }
            .tabItem {
                Label("My Eye", systemImage: "eye.fill")
            }
            .tag(1)

            NavigationStack {
                OrderHistoryListView()
                    .toolbar { cartToolbarItem }
            }
            .tabItem {
                Label("Orders", systemImage: "shippingbox")
            }
            .tag(2)

            NavigationStack {
                ProfileView()
                    .toolbar { cartToolbarItem }
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle")
            }
            .tag(3)
        }
        .sheet(isPresented: $showCart) {
            NavigationStack {
                CartView()
            }
        }
    }
}

/// Entry point for the EyeCapture tab — shows a 3-step guide before opening the camera.
struct EyeCaptureContainerView: View {
    @State private var showCapture = false

    var body: some View {
        ZStack {
            Color("BrandCream").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    stepRow(
                        icon: "lightbulb.fill",
                        title: "Find good lighting",
                        description: "Natural light works best"
                    )
                    stepRow(
                        icon: "iphone",
                        title: "Hold steady",
                        description: "Arm's length from your face"
                    )
                    stepRow(
                        icon: "eye.circle",
                        title: "Fill the oval",
                        description: "Centre your eye in the guide"
                    )
                }
                .padding(.horizontal, 32)

                Spacer()

                Button("Open Camera") {
                    showCapture = true
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("Eye Capture")
        .fullScreenCover(isPresented: $showCapture) {
            CameraView(onCapture: { _ in showCapture = false })
        }
    }

    private func stepRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color("BrandRose").opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .foregroundColor(Color("BrandRose"))
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color("BrandCharcoal"))
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}
