import Foundation
import Testing
@testable import DevActionDashboard

@Suite("HTTPStackDetector classification")
struct HTTPStackDetectorTests {
    private let detector = HTTPStackDetector()

    @Test("Detects Next.js from headers and body")
    func detectsNext() {
        let result = detector.classifyHTTP(
            headers: ["x-powered-by": "Next.js"],
            body: "<html><script id=\"__NEXT_DATA__\" type=\"application/json\">{}</script></html>"
        )
        #expect(result.stack == .nextJS)
        #expect(result.confidence == .high)
    }

    @Test("Detects ASP.NET / Kestrel")
    func detectsASPNet() {
        let result = detector.classifyHTTP(
            headers: ["Server": "Kestrel"],
            body: "<html><title>Weather</title></html>"
        )
        #expect(result.stack == .aspNet)
        #expect(result.title == "Weather")
    }

    @Test("Detects Laravel from cookie")
    func detectsLaravel() {
        let result = detector.classifyHTTP(
            headers: ["Set-Cookie": "laravel_session=abc; Path=/"],
            body: "<html><title>Laravel</title></html>"
        )
        #expect(result.stack == .laravel)
    }

    @Test("Detects React heuristics")
    func detectsReact() {
        let result = detector.classifyHTTP(
            headers: [:],
            body: "<div id=\"root\" data-reactroot></div><script src=\"/static/js/main.123.js\"></script>"
        )
        #expect(result.stack == .react)
    }

    @Test("Uses process name hints")
    func processHints() {
        let socket = ListeningSocket(
            port: 3000,
            address: "127.0.0.1",
            pid: 42,
            processName: "node",
            processPath: "/usr/local/bin/node"
        )
        let hint = detector.processHint(for: socket)
        #expect(hint.stack == .nodeJS)
    }
}

@Suite("PortsViewModel filtering")
@MainActor
struct PortsViewModelTests {
    @Test("Filters by stack and search text")
    func filters() async {
        let snapshot = PortScanSnapshot(entries: [
            LocalPortEntry(
                port: 3000,
                address: "127.0.0.1",
                pid: 1,
                processName: "node",
                processPath: nil,
                detectedStack: .nextJS,
                httpTitle: "App",
                serverHeader: nil,
                detectionConfidence: .high
            ),
            LocalPortEntry(
                port: 8080,
                address: "0.0.0.0",
                pid: 2,
                processName: "java",
                processPath: nil,
                detectedStack: .springBoot,
                httpTitle: nil,
                serverHeader: nil,
                detectionConfidence: .medium
            )
        ])

        let defaults = UserDefaults(suiteName: "PortsViewModelTests.\(UUID().uuidString)")!
        let service = PortScanService(
            scanner: StubPortScanner(snapshot: snapshot),
            browser: StubBrowser(),
            settingsStore: SettingsStore(defaults: defaults)
        )
        await service.refreshNow()

        let viewModel = PortsViewModel(portScanService: service)
        viewModel.stackFilter = .nextJS
        #expect(viewModel.visibleEntries.map(\.port) == [3000])

        viewModel.stackFilter = nil
        viewModel.searchText = "8080"
        #expect(viewModel.visibleEntries.map(\.port) == [8080])
    }
}

@Suite("PortScanService browser")
@MainActor
struct PortScanServiceBrowserTests {
    @Test("Opens browser through launcher")
    func opensBrowser() async {
        let browser = StubBrowser()
        let defaults = UserDefaults(suiteName: "PortScanServiceBrowserTests.\(UUID().uuidString)")!
        let service = PortScanService(
            scanner: StubPortScanner(snapshot: PortScanSnapshot(entries: [])),
            browser: browser,
            settingsStore: SettingsStore(defaults: defaults)
        )

        let entry = LocalPortEntry(
            port: 5173,
            address: "127.0.0.1",
            pid: 9,
            processName: "vite",
            processPath: nil,
            detectedStack: .react,
            httpTitle: nil,
            serverHeader: nil,
            detectionConfidence: .medium
        )

        await service.openInBrowser(entry)

        #expect(browser.openedURLs.map(\.absoluteString) == ["http://127.0.0.1:5173"])
        #expect(service.actionMessage != nil)
    }
}

private struct StubPortScanner: PortScanning {
    let snapshot: PortScanSnapshot

    func scan() async throws -> PortScanSnapshot {
        snapshot
    }
}

private final class StubBrowser: BrowserLaunching, @unchecked Sendable {
    private(set) var openedURLs: [URL] = []

    func open(_ url: URL) async throws {
        openedURLs.append(url)
    }
}
