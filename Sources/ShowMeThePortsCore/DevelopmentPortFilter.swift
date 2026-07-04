import Foundation

public enum DevelopmentPortFilter {
    private static let excludedProcessNames: Set<String> = [
        "airplayxpchelper",
        "apsd",
        "assistantd",
        "bluetoothd",
        "callservicesd",
        "controlcenter",
        "coreduetd",
        "coreservicesuiagent",
        "distnoted",
        "identityservicesd",
        "imagent",
        "ipnextension",
        "locationd",
        "mDNSResponder".lowercased(),
        "nearbyd",
        "rapportd",
        "remoted",
        "sharingd",
        "siriactionsd",
        "softwareupdated",
        "systemuiserver",
        "trustd",
        "universalaccessd",
        "usernoted"
    ]

    private static let developmentPortRanges: [ClosedRange<Int>] = [
        3000...9999,
        10000...10999
    ]

    private static let webServerPortRanges: [ClosedRange<Int>] = [
        3000...3999,
        4200...4299,
        5000...5001,
        5173...5179,
        8000...8999
    ]

    private static let knownWebServerPorts: Set<Int> = [
        80,
        443,
        3000,
        3001,
        3333,
        4000,
        4200,
        5000,
        5001,
        5173,
        5174,
        8000,
        8001,
        8080,
        8081,
        8443,
        8888,
        9000
    ]

    private static let knownDevelopmentPorts: Set<Int> = [
        80,
        443,
        2375,
        2376,
        3306,
        5000,
        5001,
        5037,
        5173,
        5432,
        5601,
        5672,
        6379,
        6380,
        7000,
        8000,
        8080,
        8081,
        8443,
        9000,
        9092,
        9200,
        9300,
        11211,
        15672,
        27017,
        27018,
        27019
    ]

    private static let developmentProcessKeywords = [
        "air",
        "bun",
        "cargo",
        "deno",
        "docker",
        "dotnet",
        "go",
        "gradle",
        "gunicorn",
        "httpd",
        "java",
        "mongod",
        "mysqld",
        "nginx",
        "node",
        "php",
        "postgres",
        "puma",
        "python",
        "rails",
        "redis",
        "ruby",
        "spring",
        "uvicorn",
        "vite"
    ]

    private static let webServerProcessKeywords = [
        "bun",
        "deno",
        "dotnet",
        "gunicorn",
        "httpd",
        "java",
        "next",
        "nginx",
        "node",
        "npm",
        "php",
        "pnpm",
        "puma",
        "python",
        "rails",
        "ruby",
        "spring",
        "uvicorn",
        "vite",
        "yarn"
    ]

    public static func includes(_ entry: PortEntry) -> Bool {
        let processName = entry.processName.lowercased()

        if excludedProcessNames.contains(processName) {
            return false
        }

        if knownDevelopmentPorts.contains(entry.port) {
            return true
        }

        if developmentPortRanges.contains(where: { $0.contains(entry.port) }) {
            return true
        }

        let processLooksDevelopmentRelated = developmentProcessKeywords.contains {
            processName.contains($0)
        }

        return processLooksDevelopmentRelated && entry.port < 49_152
    }

    public static func includesWebServer(_ entry: PortEntry) -> Bool {
        let processName = entry.processName.lowercased()

        if excludedProcessNames.contains(processName) {
            return false
        }

        if knownWebServerPorts.contains(entry.port) {
            return true
        }

        if webServerPortRanges.contains(where: { $0.contains(entry.port) }) {
            return true
        }

        let processLooksWebRelated = webServerProcessKeywords.contains {
            processName.contains($0)
        }

        return processLooksWebRelated && entry.port < 10_000
    }
}
