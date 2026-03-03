import SwiftUI
import StripePaymentSheet

struct CheckoutView: View {
    let order: Order

    @StateObject private var viewModel: CheckoutViewModel
    @State private var showConfirmation = false

    init(order: Order) {
        self.order = order
        _viewModel = StateObject(wrappedValue: CheckoutViewModel(order: order))
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 56))
                .foregroundColor(.accentColor)

            VStack(spacing: 8) {
                Text("Secure Payment")
                    .font(.title2.bold())
                Text("Your payment is processed securely by Stripe. IkeepAnEye never stores your card details.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 4) {
                Text("Order Total")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "$%.2f", Double(order.pricing.totalCents) / 100))
                    .font(.largeTitle.bold())
                    .foregroundColor(.accentColor)
            }

            Spacer()

            if let paymentSheet = viewModel.paymentSheet {
                PaymentSheet.PaymentButton(
                    paymentSheet: paymentSheet,
                    onCompletion: { result in
                        viewModel.handlePaymentResult(result)
                    }
                ) {
                    Text("Pay Now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            } else {
                ProgressView("Preparing payment…")
            }
        }
        .padding()
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showConfirmation) {
            OrderConfirmationView(order: order)
        }
        .task { await viewModel.loadPaymentSheet() }
        .errorAlert(message: $viewModel.errorMessage)
        .onChange(of: viewModel.paymentSucceeded) { success in
            if success { showConfirmation = true }
        }
        .onChange(of: viewModel.paymentFailed) { failed in
            if failed {
                // Reload a fresh PaymentSheet so the user can retry
                viewModel.paymentFailed = false
                Task { await viewModel.loadPaymentSheet() }
            }
        }
    }
}

@MainActor
final class CheckoutViewModel: ObservableObject {
    let order: Order

    @Published var paymentSheet: PaymentSheet?
    @Published var paymentSucceeded = false
    @Published var paymentFailed = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let stripeService = StripeService.shared

    init(order: Order) {
        self.order = order
    }

    func loadPaymentSheet() async {
        guard !paymentSucceeded, let orderId = order.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            paymentSheet = try await stripeService.makePaymentSheet(for: orderId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func handlePaymentResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            paymentSucceeded = true
        case .failed(let error):
            errorMessage = error.localizedDescription
            paymentFailed = true
        case .canceled:
            break
        }
    }
}
