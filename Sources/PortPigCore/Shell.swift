import Foundation

public struct ShellResult: Sendable {
    public let standardOutput: String
    public let standardError: String
    public let exitCode: Int32
}

public enum ShellCommandError: Error, LocalizedError, Sendable {
    case nonZeroExit(executable: String, arguments: [String], exitCode: Int32, stderr: String)

    public var errorDescription: String? {
        switch self {
        case let .nonZeroExit(executable, arguments, exitCode, stderr):
            let command = ([executable] + arguments).joined(separator: " ")
            let detail = stderr.trimmingCharacters(in: .whitespacesAndNewlines)

            if detail.isEmpty {
                return "\(command) exited with code \(exitCode)."
            }

            return "\(command) exited with code \(exitCode): \(detail)"
        }
    }
}

public struct Shell: Sendable {
    public static func run(executablePath: String, arguments: [String]) async throws -> ShellResult {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            let standardOutput = Pipe()
            let standardError = Pipe()

            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments
            process.standardOutput = standardOutput
            process.standardError = standardError

            try process.run()

            let outputData = standardOutput.fileHandleForReading.readDataToEndOfFile()
            let errorData = standardError.fileHandleForReading.readDataToEndOfFile()

            process.waitUntilExit()

            return ShellResult(
                standardOutput: String(data: outputData, encoding: .utf8) ?? "",
                standardError: String(data: errorData, encoding: .utf8) ?? "",
                exitCode: process.terminationStatus
            )
        }.value
    }
}
