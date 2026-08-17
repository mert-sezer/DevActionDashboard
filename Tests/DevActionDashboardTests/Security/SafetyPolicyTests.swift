import Foundation
import Testing
@testable import DevActionDashboard

@Suite("LocalNetworkPolicy")
struct LocalNetworkPolicyTests {
    @Test("Accepts loopback http(s) only")
    func loopbackOnly() {
        #expect(LocalNetworkPolicy.isLoopbackHTTP(URL(string: "http://127.0.0.1:3000")))
        #expect(LocalNetworkPolicy.isLoopbackHTTP(URL(string: "https://localhost")))
        #expect(LocalNetworkPolicy.isLoopbackHTTP(URL(string: "http://[::1]:8080")))
        #expect(LocalNetworkPolicy.isLoopbackHTTP(URL(string: "https://example.com")) == false)
        #expect(LocalNetworkPolicy.isLoopbackHTTP(URL(string: "file:///etc/passwd")) == false)
        #expect(LocalNetworkPolicy.isLoopbackHTTP(URL(string: "javascript:alert(1)")) == false)
    }
}

@Suite("IPAddressText")
struct IPAddressTextTests {
    @Test("Accepts IPv4 and IPv6, rejects other payloads")
    func validatesAddresses() {
        #expect(IPAddressText.isValid("1.2.3.4"))
        #expect(IPAddressText.isValid("2001:db8::1"))
        #expect(IPAddressText.isValid("<html>not an ip</html>") == false)
        #expect(IPAddressText.isValid("1.2.3.4; curl evil.example") == false)
        #expect(IPAddressText.isValid("") == false)
    }
}

@Suite("Docker safety")
struct DockerSafetyTests {
    @Test("Accepts Docker IDs and rejects flag-like values")
    func containerIDs() {
        #expect(DockerOutputParser.isContainerID("abc123def456"))
        #expect(DockerOutputParser.isContainerID("--privileged") == false)
        #expect(DockerOutputParser.isContainerID("-f") == false)
        #expect(DockerOutputParser.isContainerID("id with space") == false)
        #expect(DockerOutputParser.isContainerID("short") == false)
    }

    @Test("Requires the executable basename to be docker")
    func dockerBinaryName() {
        #expect(DockerOutputParser.isDockerBinary(at: "/usr/local/bin/docker"))
        #expect(DockerOutputParser.isDockerBinary(at: "/usr/bin/python3") == false)
        #expect(DockerOutputParser.resolveDockerExecutable(preferredPath: "/usr/bin/python3") != "/usr/bin/python3")
    }
}

@Suite("BrowserLauncher")
struct BrowserLauncherTests {
    @Test("Rejects non-loopback URLs before opening a browser")
    func rejectsRemote() async {
        guard let url = URL(string: "https://example.com") else {
            Issue.record("Failed to build test URL")
            return
        }
        let launcher = BrowserLauncher()
        do {
            try await launcher.open(url)
            Issue.record("Expected remote URL rejection")
        } catch PortError.remoteURLRejected {
            return
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
