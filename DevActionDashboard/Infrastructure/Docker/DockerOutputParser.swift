import Foundation

/// Parses Docker CLI JSON lines and human-readable stats fields.
enum DockerOutputParser {
    struct PSRow: Decodable {
        let ID: String
        let Names: String
        let Image: String
        let Status: String
        let State: String
        let Ports: String?
        let CreatedAt: String?
    }

    struct StatsRow: Decodable {
        let Container: String
        let Name: String?
        let CPUPerc: String
        let MemUsage: String
        let MemPerc: String
    }

    static func decodeJSONLines<T: Decodable>(_ output: String, as type: T.Type) throws -> [T] {
        let lines = output
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let decoder = JSONDecoder()
        do {
            return try lines.map { line in
                guard let data = line.data(using: .utf8) else {
                    throw DockerError.decodingFailed("Invalid UTF-8 in Docker JSON line")
                }
                return try decoder.decode(T.self, from: data)
            }
        } catch let error as DockerError {
            throw error
        } catch {
            throw DockerError.decodingFailed(error.localizedDescription)
        }
    }

    static func containers(fromPSOutput output: String) throws -> [DockerContainer] {
        let rows = try decodeJSONLines(output, as: PSRow.self)
        return rows.map { row in
            DockerContainer(
                containerID: row.ID,
                name: row.Names,
                image: row.Image,
                status: row.Status,
                state: DockerContainerState(dockerState: row.State),
                ports: row.Ports ?? "",
                createdAt: row.CreatedAt ?? ""
            )
        }
    }

    static func stats(fromStatsOutput output: String) throws -> [DockerContainerStats] {
        let rows = try decodeJSONLines(output, as: StatsRow.self)
        return rows.map { row in
            let memory = parseMemoryUsage(row.MemUsage)
            return DockerContainerStats(
                containerID: row.Container,
                cpuUsageRatio: parsePercentage(row.CPUPerc),
                memoryUsageBytes: memory.used,
                memoryLimitBytes: memory.limit,
                memoryUsageRatio: parsePercentage(row.MemPerc)
            )
        }
    }

    static func parsePercentage(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "%", with: "")
        guard let value = Double(trimmed) else { return nil }
        return max(value / 100.0, 0)
    }

    /// Parses values like `10.5MiB / 7.653GiB`.
    static func parseMemoryUsage(_ raw: String) -> (used: UInt64?, limit: UInt64?) {
        let parts = raw.split(separator: "/").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard parts.count == 2 else { return (nil, nil) }
        return (parseByteQuantity(parts[0]), parseByteQuantity(parts[1]))
    }

    static func parseByteQuantity(_ raw: String) -> UInt64? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let pattern = #"^\s*([0-9]*\.?[0-9]+)\s*([A-Za-z]+)?\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
        guard let match = regex.firstMatch(in: trimmed, range: range),
              let valueRange = Range(match.range(at: 1), in: trimmed),
              let value = Double(trimmed[valueRange])
        else {
            return nil
        }

        let unit: String
        if match.range(at: 2).location != NSNotFound, let unitRange = Range(match.range(at: 2), in: trimmed) {
            unit = String(trimmed[unitRange]).lowercased()
        } else {
            unit = "b"
        }

        let multiplier: Double
        switch unit {
        case "b": multiplier = 1
        case "kb", "kib": multiplier = 1_024
        case "mb", "mib": multiplier = 1_024 * 1_024
        case "gb", "gib": multiplier = 1_024 * 1_024 * 1_024
        case "tb", "tib": multiplier = 1_024 * 1_024 * 1_024 * 1_024
        default: return nil
        }

        return UInt64(value * multiplier)
    }

    static func isContainerID(_ value: String) -> Bool {
        let allowed = CharacterSet.alphanumerics
        guard (8...128).contains(value.count) else { return false }
        return value.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    static func isDockerBinary(at path: String) -> Bool {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        return url.path.hasPrefix("/") && url.lastPathComponent == "docker"
    }

    static func resolveDockerExecutable(preferredPath: String) -> String? {
        let candidates = [
            preferredPath,
            "/opt/homebrew/bin/docker",
            "/usr/local/bin/docker",
            "/usr/bin/docker"
        ]

        let fileManager = FileManager.default
        for candidate in candidates where !candidate.isEmpty {
            if candidate == "docker" {
                if let path = searchPATH(for: "docker"), isDockerBinary(at: path) {
                    return path
                }
                continue
            }
            let resolved = URL(fileURLWithPath: candidate).standardizedFileURL.path
            if isDockerBinary(at: resolved), fileManager.isExecutableFile(atPath: resolved) {
                return resolved
            }
        }
        return nil
    }

    private static func searchPATH(for executable: String) -> String? {
        let path = ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin"
        for directory in path.split(separator: ":") {
            let full = URL(fileURLWithPath: String(directory)).appendingPathComponent(executable).path
            if FileManager.default.isExecutableFile(atPath: full) {
                return full
            }
        }
        return nil
    }
}
