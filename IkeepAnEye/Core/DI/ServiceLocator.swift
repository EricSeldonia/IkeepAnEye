import Foundation

/// Simple service locator for dependency injection.
/// Register services at app startup; resolve them throughout the app.
final class ServiceLocator {
    static let shared = ServiceLocator()
    private init() {}

    private var services: [ObjectIdentifier: Any] = [:]

    func register<T>(_ service: T) {
        let key = ObjectIdentifier(type(of: service) as AnyObject.Type)
        services[key] = service
    }

    func register<T>(_ service: T, as type: T.Type) {
        services[ObjectIdentifier(type)] = service
    }

    func resolve<T>() -> T {
        let key = ObjectIdentifier(T.self)
        guard let service = services[key] as? T else {
            fatalError("Service \(T.self) not registered in ServiceLocator")
        }
        return service
    }

    func tryResolve<T>() -> T? {
        let key = ObjectIdentifier(T.self)
        return services[key] as? T
    }
}
