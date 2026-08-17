import Foundation
import SystemConfiguration

/// Reads configured DNS servers from the dynamic store.
struct DNSConfigurationSampler: Sendable {
    func sample() -> [String] {
        guard let store = SCDynamicStoreCreate(nil, "DevActionDashboard" as CFString, nil, nil) else {
            return []
        }

        let key = "State:/Network/Global/DNS" as CFString
        guard
            let raw = SCDynamicStoreCopyValue(store, key) as? [String: Any],
            let servers = raw["ServerAddresses"] as? [String]
        else {
            return []
        }

        return servers
    }
}
