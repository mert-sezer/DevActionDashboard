import Foundation
import Testing
@testable import DevActionDashboard

@Suite("SensitiveDisplay")
struct SensitiveDisplayTests {
    @Test("Leaves empty and unavailable values unmasked")
    func skipsEmptyValues() {
        #expect(SensitiveDisplay.isMaskable("") == false)
        #expect(SensitiveDisplay.isMaskable("   ") == false)
        #expect(SensitiveDisplay.isMaskable("—") == false)
        #expect(SensitiveDisplay.display("—", isRevealed: false) == "—")
        #expect(SensitiveDisplay.display("", isRevealed: false).isEmpty)
    }

    @Test("Masks secret values until revealed")
    func masksUntilRevealed() {
        let ip = "192.168.1.20"
        #expect(SensitiveDisplay.isMaskable(ip))
        #expect(SensitiveDisplay.display(ip, isRevealed: false) == SensitiveDisplay.placeholder)
        #expect(SensitiveDisplay.display(ip, isRevealed: true) == ip)
    }

    @Test("Uses a fixed placeholder so value length does not leak")
    func usesFixedPlaceholder() {
        let ipv4 = SensitiveDisplay.display("10.0.0.2", isRevealed: false)
        let ipv6 = SensitiveDisplay.display("2001:db8::1", isRevealed: false)
        #expect(ipv4 == ipv6)
        #expect(ipv4 == SensitiveDisplay.placeholder)
    }
}
