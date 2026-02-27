import Foundation

struct Address: Codable, Equatable, Hashable {
    var fullName: String
    var line1: String
    var line2: String?
    var city: String
    var state: String
    var postalCode: String
    var country: String

    var formatted: String {
        let parts: [String] = [
            fullName,
            line1,
            line2.map { $0 } ?? "",
            "\(city), \(state) \(postalCode)",
            country
        ].filter { !$0.isEmpty }
        return parts.joined(separator: "\n")
    }
}
