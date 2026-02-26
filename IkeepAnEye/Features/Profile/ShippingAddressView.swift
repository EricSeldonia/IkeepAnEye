import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ShippingAddressView: View {
    @StateObject private var viewModel = ShippingAddressViewModel()
    @State private var showAddressSheet = false

    var body: some View {
        List {
            if let address = viewModel.address {
                Section("Default Address") {
                    Text(address.formatted)
                        .font(.subheadline)
                        .padding(.vertical, 4)
                }
                Section {
                    Button("Edit Address") { showAddressSheet = true }
                }
            } else {
                Section {
                    Button("Add Default Address") { showAddressSheet = true }
                        .buttonStyle(.borderless)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Shipping Address")
        .task { await viewModel.load() }
        .sheet(isPresented: $showAddressSheet) {
            AddressEntryView(address: $viewModel.address)
                .onDisappear { Task { await viewModel.save() } }
        }
        .loadingOverlay(viewModel.isLoading)
        .errorAlert(message: $viewModel.errorMessage)
    }
}

@MainActor
final class ShippingAddressViewModel: ObservableObject {
    @Published var address: Address?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func load() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            if let data = doc.data(), let raw = data["defaultShipping"] {
                let json = try JSONSerialization.data(withJSONObject: raw)
                address = try JSONDecoder().decode(Address.self, from: json)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() async {
        guard let uid = Auth.auth().currentUser?.uid,
              let address else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let encoded = try JSONEncoder().encode(address)
            let dict = (try JSONSerialization.jsonObject(with: encoded)) as? [String: Any] ?? [:]
            try await db.collection("users").document(uid).updateData(["defaultShipping": dict])
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
