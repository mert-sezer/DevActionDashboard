import Foundation

/// Supplies the ordered set of feature modules shown in the app shell.
@MainActor
public protocol FeatureRegistry: AnyObject {
    var modules: [any FeatureModule] { get }

    func module(for id: FeatureID) -> (any FeatureModule)?
}

public extension FeatureRegistry {
    func module(for id: FeatureID) -> (any FeatureModule)? {
        modules.first { $0.id == id }
    }
}
