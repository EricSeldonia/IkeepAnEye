import Foundation

@MainActor
final class CatalogGridViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let productService = ProductService.shared

    func onAppear() {
        products = productService.products
        isLoading = productService.isLoading
        productService.startListening()
        observeService()
    }

    func onDisappear() {
        // Keep listening so data is warm when returning to the tab
    }

    private func observeService() {
        // Mirror ProductService published values
        Task { @MainActor in
            for await _ in Timer.publish(every: 0.3, on: .main, in: .default).autoconnect().values {
                self.products = productService.products
                self.isLoading = productService.isLoading
                self.errorMessage = productService.errorMessage
            }
        }
    }
}
