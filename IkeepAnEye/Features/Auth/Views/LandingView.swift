import SwiftUI

struct LandingView: View {
    @State private var showGuestCatalog = false

    var body: some View {
        ZStack {
            Color("BrandCream").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Hero
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color("BrandRose").opacity(0.08), lineWidth: 1)
                            .frame(width: 200, height: 200)
                        Circle()
                            .stroke(Color("BrandRose").opacity(0.15), lineWidth: 1)
                            .frame(width: 152, height: 152)
                        Image(systemName: "eye.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color("BrandRose"))
                    }

                    Text("IkeepAnEye")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundColor(Color("BrandCharcoal"))

                    Text("Wear your eye. Always close.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // CTAs
                VStack(spacing: 12) {
                    NavigationLink(destination: SignUpView()) {
                        Text("Create Account")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    NavigationLink(destination: SignInView()) {
                        Text("Sign In")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button("Browse our collection →") {
                        showGuestCatalog = true
                    }
                    .font(.subheadline)
                    .foregroundColor(Color("BrandRose"))
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showGuestCatalog) {
            NavigationStack { CatalogGridView() }
        }
    }
}
