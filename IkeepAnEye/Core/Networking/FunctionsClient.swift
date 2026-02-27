import Foundation
import FirebaseFunctions

/// Typed wrapper around Firebase Callable Functions.
/// Automatically uses the local emulator when `USE_EMULATOR=1` is set.
final class FunctionsClient {
    private let functions: Functions

    init() {
        functions = Functions.functions()
#if DEBUG
        if ProcessInfo.processInfo.environment["USE_EMULATOR"] == "1" {
            functions.useEmulator(withHost: "127.0.0.1", port: 5001)
        }
#endif
    }

    /// Calls a Firebase Callable Function and decodes the result.
    func call<Request: Encodable, Response: Decodable>(
        name: String,
        data: Request
    ) async throws -> Response {
        let encoded = try encodeToDict(data)
        let result = try await functions.httpsCallable(name).call(encoded)
        let jsonData = try JSONSerialization.data(withJSONObject: result.data)
        return try JSONDecoder().decode(Response.self, from: jsonData)
    }

    private func encodeToDict<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        let json = try JSONSerialization.jsonObject(with: data)
        guard let dict = json as? [String: Any] else {
            throw FunctionsClientError.encodingFailed
        }
        return dict
    }
}

enum FunctionsClientError: LocalizedError {
    case emptyResponse
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .emptyResponse: return "The Cloud Function returned an empty response."
        case .encodingFailed: return "Failed to encode request data."
        }
    }
}
