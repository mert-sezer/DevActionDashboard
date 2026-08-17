import Foundation

/// Shared formatting helpers for metrics UI.
enum MetricsFormatter {
    static func bytes(_ value: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        formatter.allowsNonnumericFormatting = false
        return formatter.string(fromByteCount: Int64(clamping: value))
    }

    static func percent(_ ratio: Double?) -> String {
        guard let ratio else { return "—" }
        return String(format: "%.0f%%", ratio * 100)
    }

    static func uptime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let days = total / 86_400
        let hours = (total % 86_400) / 3_600
        let minutes = (total % 3_600) / 60

        var parts: [String] = []
        if days > 0 { parts.append("\(days)d") }
        if hours > 0 || days > 0 { parts.append("\(hours)h") }
        parts.append("\(minutes)m")
        return parts.joined(separator: " ")
    }

    static func bytesPerSecond(_ value: Double?) -> String {
        guard let value else { return "—" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        formatter.allowsNonnumericFormatting = false
        let bytes = formatter.string(fromByteCount: Int64(clamping: UInt64(max(value, 0).rounded())))
        return "\(bytes)/s"
    }

    static func milliseconds(_ value: Double?) -> String {
        guard let value else { return "—" }
        if value < 10 {
            return String(format: "%.1f ms", value)
        }
        return String(format: "%.0f ms", value)
    }
}
