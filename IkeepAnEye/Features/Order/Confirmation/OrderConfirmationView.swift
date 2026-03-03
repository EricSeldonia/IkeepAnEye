import SwiftUI

struct OrderConfirmationView: View {
    let order: Order
    @EnvironmentObject private var cartStore: CartStore

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundColor(.green)

            VStack(spacing: 8) {
                Text("Order Confirmed!")
                    .font(.title.bold())
                if let id = order.id {
                    Text("Order #\(id.prefix(8).uppercased())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            VStack(spacing: 6) {
                Text("We're crafting your unique pendant.")
                    .font(.subheadline)
                Text("You'll receive an email when it ships.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal)

            VStack(spacing: 4) {
                HStack {
                    Text("Shipping to:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                Text(order.shipping.formatted)
                    .font(.subheadline)
            }
            .padding()
            .cardStyle()
            .padding(.horizontal)

            Spacer()

            Button("Continue Shopping") {
                cartStore.clear()
                cartStore.shouldDismiss = true
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .onAppear {
            let orderIds = [order.id].compactMap { $0 }
            AnalyticsService.shared.track("payment_completed", payload: [
                "orderIds": orderIds,
            ])
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Confirmed")
        .navigationBarTitleDisplayMode(.inline)
    }
}
