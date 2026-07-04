import Foundation

public struct PortEntry: Identifiable, Hashable, Sendable {
    public let processName: String
    public let pid: Int32
    public let port: Int
    public let protocolName: String
    public let endpoint: String

    public var id: String {
        "\(pid)-\(protocolName)-\(port)"
    }

    public init(
        processName: String,
        pid: Int32,
        port: Int,
        protocolName: String,
        endpoint: String
    ) {
        self.processName = processName
        self.pid = pid
        self.port = port
        self.protocolName = protocolName
        self.endpoint = endpoint
    }
}
