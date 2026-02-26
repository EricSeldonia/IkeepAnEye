import SwiftUI

struct OrderConfirmationView: View {
    let order: Order
    @Environment(\.dismiss) private var dismiss

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
                Text("We're crafting your unique iris pendant.")
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
                // Pop to root — NavigationStack handles this via path reset
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Confirmed")
        .navigationBarTitleDisplayMode(.inline)
    }
}
