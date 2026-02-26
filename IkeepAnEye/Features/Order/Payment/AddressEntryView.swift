import SwiftUI

/// Reusable address entry sheet. Used in CartView and ShippingAddressView.
struct AddressEntryView: View {
    @Binding var address: Address?
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var line1 = ""
    @State private var line2 = ""
    @State private var city = ""
    @State private var state = ""
    @State private var postalCode = ""
    @State private var country = "US"

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact") {
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                }
                Section("Address") {
                    TextField("Street Address", text: $line1)
                        .textContentType(.streetAddressLine1)
                    TextField("Apt, Suite, etc. (optional)", text: $line2)
                        .textContentType(.streetAddressLine2)
                    TextField("City", text: $city)
                        .textContentType(.addressCity)
                    TextField("State / Province", text: $state)
                        .textContentType(.addressState)
                    TextField("Postal Code", text: $postalCode)
                        .keyboardType(.numbersAndPunctuation)
                        .textContentType(.postalCode)
                    TextField("Country (e.g. US)", text: $country)
                        .textContentType(.countryName)
                }
            }
            .navigationTitle("Shipping Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                        .bold()
                }
            }
            .onAppear { prefill() }
        }
    }

    private var isValid: Bool {
        !fullName.isEmpty && !line1.isEmpty && !city.isEmpty &&
        !state.isEmpty && !postalCode.isEmpty && !country.isEmpty
    }

    private func prefill() {
        guard let address else { return }
        fullName   = address.fullName
        line1      = address.line1
        line2      = address.line2 ?? ""
        city       = address.city
        state      = address.state
        postalCode = address.postalCode
        country    = address.country
    }

    private func save() {
        address = Address(
            fullName: fullName,
            line1: line1,
            line2: line2.isEmpty ? nil : line2,
            city: city,
            state: state,
            postalCode: postalCode,
            country: country
        )
        dismiss()
    }
}
