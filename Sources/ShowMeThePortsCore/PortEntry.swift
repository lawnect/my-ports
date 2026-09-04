import Foundation

public struct PortEntry: Identifiable, Hashable, Sendable {
    public let processName: String
    public let pid: Int32
    public let port: Int
    public let protocolName: String
    public let endpoint: String
    public let parentPID: Int32?
    public let userID: UInt32?
    public let executablePath: String?
    public let ancestorExecutablePaths: [String]

    public var id: String {
        "\(pid)-\(protocolName)-\(port)"
    }

    public var classification: PortClassification {
        DevelopmentPortFilter.classify(self)
    }

    public init(
        processName: String,
        pid: Int32,
        port: Int,
        protocolName: String,
        endpoint: String,
        parentPID: Int32? = nil,
        userID: UInt32? = nil,
        executablePath: String? = nil,
        ancestorExecutablePaths: [String] = []
    ) {
        self.processName = processName
        self.pid = pid
        self.port = port
        self.protocolName = protocolName
        self.endpoint = endpoint
        self.parentPID = parentPID
        self.userID = userID
        self.executablePath = executablePath
        self.ancestorExecutablePaths = ancestorExecutablePaths
    }
}
