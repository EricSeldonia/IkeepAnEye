import Foundation
import Combine

@MainActor
final class CatalogGridViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let productService = ProductService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        productService.$products
            .combineLatest(productService.$isLoading, productService.$errorMessage)
            .receive(on: RunLoop.main)
            .sink { [weak self] products, isLoading, errorMessage in
                self?.products = products
                self?.isLoading = isLoading
                self?.errorMessage = errorMessage
            }
            .store(in: &cancellables)
    }

    func onAppear() {
        products = productService.products
        isLoading = productService.isLoading
        productService.startListening()
    }

    func onDisappear() {
        // Keep listening so data is warm when returning to the tab
    }
}
