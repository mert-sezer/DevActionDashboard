import Foundation
import IOKit.ps

/// Reads battery / power-source state via IOKit power sources (nil on desktops without a battery).
struct BatterySampler: Sendable {
    func sample() -> BatteryMetrics? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            return nil
        }
        guard let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else {
            return nil
        }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            let type = description[kIOPSTypeKey] as? String
            guard type == kIOPSInternalBatteryType else { continue }

            let current = description[kIOPSCurrentCapacityKey] as? Int
            let max = description[kIOPSMaxCapacityKey] as? Int
            let chargeRatio: Double?
            if let current, let max, max > 0 {
                chargeRatio = Double(current) / Double(max)
            } else {
                chargeRatio = nil
            }

            let isCharging = description[kIOPSIsChargingKey] as? Bool ?? false
            let powerState = description[kIOPSPowerSourceStateKey] as? String
            let isACPowered = powerState == kIOPSACPowerValue
            let health = description[kIOPSBatteryHealthKey] as? String

            return BatteryMetrics(
                chargeRatio: chargeRatio,
                isCharging: isCharging,
                isACPowered: isACPowered,
                healthDescription: health
            )
        }

        return nil
    }
}
