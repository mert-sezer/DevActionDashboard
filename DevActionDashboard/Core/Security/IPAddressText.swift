import Darwin
import Foundation

/// Strict IPv4 / IPv6 text validation.
enum IPAddressText {
    static func isValid(_ raw: String) -> Bool {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= 45 else { return false }

        return value.withCString { pointer in
            var ipv4 = in_addr()
            var ipv6 = in6_addr()
            return inet_pton(AF_INET, pointer, &ipv4) == 1
                || inet_pton(AF_INET6, pointer, &ipv6) == 1
        }
    }
}
