import Foundation

/// Stable identifier for a feature module registered with the app shell.
public struct FeatureID: Hashable, Sendable, Codable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

public extension FeatureID {
    static let dashboard = FeatureID("dashboard")
    static let system = FeatureID("system")
    static let processes = FeatureID("processes")
    static let network = FeatureID("network")
    static let ports = FeatureID("ports")
    static let docker = FeatureID("docker")
    static let environment = FeatureID("environment")
    static let envVars = FeatureID("envVars")
    static let utilities = FeatureID("utilities")
    static let actions = FeatureID("actions")
    static let settings = FeatureID("settings")
    static let about = FeatureID("about")
}
