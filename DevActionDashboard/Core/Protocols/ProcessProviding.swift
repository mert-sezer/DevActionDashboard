import Foundation

/// Lists running processes and applies process control operations.
public protocol ProcessProviding: Sendable {
    func listProcesses() async throws -> ProcessListSnapshot
    func terminateProcess(pid: Int32, force: Bool) async throws
}

/// Opens Apple Activity Monitor.
public protocol ActivityMonitorLaunching: Sendable {
    func openActivityMonitor() async throws
}
