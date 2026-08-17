import AppKit
import Foundation

/// Opens loopback http(s) URLs with the user's default browser.
struct BrowserLauncher: BrowserLaunching {
    func open(_ url: URL) async throws {
        guard LocalNetworkPolicy.isLoopbackHTTP(url) else {
            throw PortError.remoteURLRejected
        }
        let success = NSWorkspace.shared.open(url)
        guard success else {
            throw PortError.browserOpenFailed
        }
        AppLog.ports.info("Opened browser for \(url.absoluteString, privacy: .public)")
    }
}
