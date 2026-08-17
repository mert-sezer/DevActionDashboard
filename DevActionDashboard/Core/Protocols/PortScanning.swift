import Foundation

/// Discovers listening localhost TCP ports and fingerprints local dev servers.
public protocol PortScanning: Sendable {
    func scan() async throws -> PortScanSnapshot
}

/// Opens a URL in the default browser.
public protocol BrowserLaunching: Sendable {
    func open(_ url: URL) async throws
}
