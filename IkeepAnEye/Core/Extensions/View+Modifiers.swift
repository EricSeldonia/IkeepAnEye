import SwiftUI

extension View {
    /// Applies a card-style background with rounded corners and shadow.
    func cardStyle(cornerRadius: CGFloat = 12) -> some View {
        self
            .background(Color("BrandCream"))
            .cornerRadius(cornerRadius)
            .shadow(color: Color("BrandRose").opacity(0.06), radius: 8, x: 0, y: 2)
    }

    /// Hides the view when condition is true.
    func hidden(_ shouldHide: Bool) -> some View {
        opacity(shouldHide ? 0 : 1)
    }

    /// Overlays a loading spinner when `isLoading` is true.
    func loadingOverlay(_ isLoading: Bool) -> some View {
        overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(1.4)
                }
            }
        }
    }

    /// Shows an error alert bound to an optional error message.
    func errorAlert(message: Binding<String?>) -> some View {
        alert("Error", isPresented: Binding(
            get: { message.wrappedValue != nil },
            set: { if !$0 { message.wrappedValue = nil } }
        )) {
            Button("OK", role: .cancel) { message.wrappedValue = nil }
        } message: {
            Text(message.wrappedValue ?? "")
        }
    }

    /// Warm thin-border text field style.
    func brandTextField() -> some View {
        self
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color("BrandRose").opacity(0.3), lineWidth: 1)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("BrandRose").opacity(configuration.isPressed ? 0.7 : 1))
            .cornerRadius(12)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(Color("BrandRose"))
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("BrandRose").opacity(configuration.isPressed ? 0.18 : 0.12))
            .cornerRadius(12)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
