import Foundation

public struct LsofPortScanner: Sendable {
    private let lsofPath: String
    private let psPath: String

    public init(lsofPath: String = "/usr/sbin/lsof", psPath: String = "/bin/ps") {
        self.lsofPath = lsofPath
        self.psPath = psPath
    }

    public func listeningPorts() async throws -> [PortEntry] {
        let arguments = ["-nP", "-iTCP", "-sTCP:LISTEN", "-F", "pcPRun"]
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

        let entries = Self.parse(result.standardOutput)

        guard !entries.isEmpty else {
            return []
        }

        let processResult = try? await Shell.run(
            executablePath: psPath,
            arguments: ["-axo", "pid=,ppid=,uid=,comm="]
        )

        guard let processResult, processResult.exitCode == 0 else {
            return entries
        }

        return Self.applyingProcessMetadata(
            to: entries,
            processListOutput: processResult.standardOutput
        )
    }

    public static func parse(_ output: String) -> [PortEntry] {
        var currentPID: Int32?
        var currentParentPID: Int32?
        var currentUserID: UInt32?
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
                currentParentPID = nil
                currentUserID = nil
                currentProcessName = "Unknown"
                currentProtocol = "TCP"
            case "R":
                currentParentPID = Int32(value)
            case "u":
                currentUserID = UInt32(value)
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
                        endpoint: value,
                        parentPID: currentParentPID,
                        userID: currentUserID
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

    static func applyingProcessMetadata(
        to entries: [PortEntry],
        processListOutput: String
    ) -> [PortEntry] {
        let processTable = parseProcessList(processListOutput)

        return entries.map { entry in
            let record = processTable[entry.pid]
            let parentPID = entry.parentPID ?? record?.parentPID
            var ancestorPaths: [String] = []
            var visited = Set<Int32>()
            var nextPID = parentPID

            while let pid = nextPID, pid > 1, visited.insert(pid).inserted, ancestorPaths.count < 8 {
                guard let ancestor = processTable[pid] else {
                    break
                }

                if !ancestor.executablePath.isEmpty {
                    ancestorPaths.append(ancestor.executablePath)
                }
                nextPID = ancestor.parentPID
            }

            return PortEntry(
                processName: entry.processName,
                pid: entry.pid,
                port: entry.port,
                protocolName: entry.protocolName,
                endpoint: entry.endpoint,
                parentPID: parentPID,
                userID: entry.userID ?? record?.userID,
                executablePath: record?.executablePath,
                ancestorExecutablePaths: ancestorPaths
            )
        }
    }

    private struct ProcessRecord {
        let parentPID: Int32
        let userID: UInt32
        let executablePath: String
    }

    private static func parseProcessList(_ output: String) -> [Int32: ProcessRecord] {
        var records: [Int32: ProcessRecord] = [:]

        for line in output.split(whereSeparator: \.isNewline) {
            let fields = line.split(maxSplits: 3, whereSeparator: \.isWhitespace)
            guard fields.count == 4,
                  let pid = Int32(fields[0]),
                  let parentPID = Int32(fields[1]),
                  let userID = UInt32(fields[2]) else {
                continue
            }

            records[pid] = ProcessRecord(
                parentPID: parentPID,
                userID: userID,
                executablePath: String(fields[3])
            )
        }

        return records
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
