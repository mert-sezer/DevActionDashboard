import Foundation

/// Resolves executables from PATH and known install locations.
enum ExecutableResolver {
    static func resolve(
        named name: String,
        extraCandidates: [String] = []
    ) -> String? {
        guard isSafeExecutableName(name) else { return nil }

        var candidates = extraCandidates.filter { candidate in
            candidate.hasPrefix("/") && URL(fileURLWithPath: candidate).lastPathComponent == name
        }
        candidates.append(contentsOf: pathCandidates(for: name))

        let fileManager = FileManager.default
        var seen = Set<String>()
        for candidate in candidates where !candidate.isEmpty {
            guard seen.insert(candidate).inserted else { continue }
            if fileManager.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }
        return nil
    }

    static func pathCandidates(for name: String) -> [String] {
        guard isSafeExecutableName(name) else { return [] }
        let path = ProcessInfo.processInfo.environment["PATH"]
            ?? "/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin"
        return path.split(separator: ":").map { directory in
            URL(fileURLWithPath: String(directory)).appendingPathComponent(name).path
        }
    }

    private static func isSafeExecutableName(_ name: String) -> Bool {
        guard !name.isEmpty, !name.contains("/"), !name.contains("\\") else { return false }
        guard name != "." && name != ".." else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" || $0 == "." }
    }
}
