import Foundation

/// Masks secret-like values (IP addresses, tokens) until the user reveals them.
enum SensitiveDisplay {
    static let placeholder = "••••••••"
    static let unavailable = "—"

    static func isMaskable(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != unavailable
    }

    static func display(_ value: String, isRevealed: Bool) -> String {
        guard isMaskable(value), !isRevealed else { return value }
        return placeholder
    }
}
