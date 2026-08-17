import Foundation
import Testing
@testable import DevActionDashboard

@Suite("DeveloperUtilityEngine")
struct DeveloperUtilityEngineTests {
    @Test("Formats and compares JSON")
    func jsonTools() throws {
        let formatted = try DeveloperUtilityEngine.formatJSON("{\"b\":1,\"a\":2}").get()
        #expect(formatted.contains("\n"))
        let compare = try DeveloperUtilityEngine.compareJSON(
            left: "{\"a\":1,\"b\":2}",
            right: "{\"b\":2,\"a\":1}"
        ).get()
        #expect(compare.areEqual)
    }

    @Test("Encodes and decodes Base64")
    func base64() throws {
        let encoded = DeveloperUtilityEngine.base64Encode("hello")
        let decoded = try DeveloperUtilityEngine.base64Decode(encoded).get()
        #expect(decoded == "hello")
    }

    @Test("Hashes with SHA-256")
    func hash() {
        let digest = DeveloperUtilityEngine.hash("abc", algorithm: .sha256)
        #expect(digest == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    @Test("Decodes JWT header and payload")
    func jwt() throws {
        // {"alg":"none"} . {"sub":"123"}
        let header = Data("{\"alg\":\"none\"}".utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let payload = Data("{\"sub\":\"123\"}".utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let token = "\(header).\(payload).sig"
        let result = try DeveloperUtilityEngine.decodeJWT(token).get()
        #expect(result.headerJSON.contains("alg"))
        #expect(result.payloadJSON.contains("123"))
        #expect(result.signaturePresent)
    }

    @Test("Tests regex matches")
    func regex() throws {
        let result = try DeveloperUtilityEngine.testRegex(pattern: #"(\w+)"#, text: "a b").get()
        #expect(result.matches.count == 2)
    }

    @Test("Describes cron expressions")
    func cron() throws {
        let description = try DeveloperUtilityEngine.describeCron("*/5 * * * *").get()
        #expect(description.contains("every 5 minutes"))
    }

    @Test("Converts unix timestamps")
    func timestamp() throws {
        let result = try DeveloperUtilityEngine.convertTimestamp("0").get()
        #expect(Int(result.unixSeconds) == 0)
    }
}
