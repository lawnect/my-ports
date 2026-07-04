import Foundation

public struct LsofPortScanner: Sendable {
    private let lsofPath: String

    public init(lsofPath: String = "/usr/sbin/lsof") {
        self.lsofPath = lsofPath
    }

    public func listeningPorts() async throws -> [PortEntry] {
        let arguments = ["-nP", "-iTCP", "-sTCP:LISTEN", "-F", "pcPn"]
        let result = try await Shell.run(executablePath: lsofPath, arguments: arguments)

        if result.exitCode != 0 && result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if result.exitCode == 1 {
                return []
            }

            throw ShellCommandError.nonZeroExit(
                executable: lsofPath,
                arguments: arguments,
                exitCode: result.exitCode,
                stderr: result.standardError
            )
        }

        return Self.parse(result.standardOutput)
    }

    public static func parse(_ output: String) -> [PortEntry] {
        var currentPID: Int32?
        var currentProcessName = "Unknown"
        var currentProtocol = "TCP"
        var ports: [PortEntry] = []
        var seen = Set<String>()

        for rawLine in output.split(whereSeparator: \.isNewline) {
            guard let field = rawLine.first else {
                continue
            }

            let value = String(rawLine.dropFirst())

            switch field {
            case "p":
                currentPID = Int32(value)
                currentProcessName = "Unknown"
                currentProtocol = "TCP"
            case "c":
                currentProcessName = value.isEmpty ? "Unknown" : value
            case "P":
                currentProtocol = value.isEmpty ? "TCP" : value
            case "n":
                guard let pid = currentPID, let port = extractPort(from: value) else {
                    continue
                }

                let dedupeKey = "\(pid)-\(currentProtocol)-\(port)"
                guard !seen.contains(dedupeKey) else {
                    continue
                }

                seen.insert(dedupeKey)
                ports.append(
                    PortEntry(
                        processName: currentProcessName,
                        pid: pid,
                        port: port,
                        protocolName: currentProtocol,
                        endpoint: value
                    )
                )
            default:
                continue
            }
        }

        return ports.sorted {
            if $0.port != $1.port {
                return $0.port < $1.port
            }

            if $0.processName != $1.processName {
                return $0.processName.localizedCaseInsensitiveCompare($1.processName) == .orderedAscending
            }

            return $0.pid < $1.pid
        }
    }

    private static func extractPort(from endpoint: String) -> Int? {
        let firstSegment = endpoint
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .first

        guard let firstSegment, let separatorIndex = firstSegment.lastIndex(of: ":") else {
            return nil
        }

        let portValue = firstSegment[firstSegment.index(after: separatorIndex)...]
        return Int(portValue)
    }
}
