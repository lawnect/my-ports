import Foundation

public struct ProcessPortKiller: Sendable {
    private let killPath: String

    public init(killPath: String = "/bin/kill") {
        self.killPath = killPath
    }

    public func kill(pid: Int32) async throws {
        let arguments = ["-9", String(pid)]
        let result = try await Shell.run(executablePath: killPath, arguments: arguments)

        guard result.exitCode == 0 else {
            throw ShellCommandError.nonZeroExit(
                executable: killPath,
                arguments: arguments,
                exitCode: result.exitCode,
                stderr: result.standardError
            )
        }
    }
}
