import Foundation

public enum DevelopmentPortFilter {
    private struct Service {
        let category: PortCategory
        let name: String
        let iconName: String?

        init(category: PortCategory, name: String, iconName: String? = nil) {
            self.category = category
            self.name = name
            self.iconName = iconName
        }
    }

    private static let excludedProcessNames: Set<String> = [
        "airplayxpchelper", "apsd", "assistantd", "bluetoothd", "callservicesd",
        "controlcenter", "coreduetd", "coreservicesuiagent", "distnoted",
        "identityservicesd", "imagent", "ipnextension", "locationd",
        "mdnsresponder", "nearbyd", "rapportd", "remoted", "sharingd",
        "siriactionsd", "softwareupdated", "systemuiserver", "trustd",
        "universalaccessd", "usernoted"
    ]

    private static let knownServices: [Int: Service] = [
        80: Service(category: .web, name: "HTTP"),
        443: Service(category: .web, name: "HTTPS"),
        2375: Service(category: .container, name: "Docker", iconName: "docker"),
        2376: Service(category: .container, name: "Docker TLS", iconName: "docker"),
        3000: Service(category: .web, name: "Web server"),
        3001: Service(category: .web, name: "Web server"),
        3306: Service(category: .database, name: "MySQL", iconName: "mysql"),
        3333: Service(category: .web, name: "Web server"),
        4000: Service(category: .web, name: "Web server"),
        4200: Service(category: .web, name: "Angular", iconName: "angular"),
        4369: Service(category: .development, name: "Erlang Port Mapper", iconName: "elixir"),
        5000: Service(category: .web, name: "Web server"),
        5001: Service(category: .web, name: "Web server"),
        5037: Service(category: .mobile, name: "Android Debug Bridge", iconName: "android"),
        5173: Service(category: .web, name: "Vite", iconName: "vite"),
        5174: Service(category: .web, name: "Vite", iconName: "vite"),
        5432: Service(category: .database, name: "PostgreSQL", iconName: "postgresql"),
        5601: Service(category: .development, name: "Kibana", iconName: "elasticsearch"),
        5672: Service(category: .messaging, name: "RabbitMQ", iconName: "rabbitmq"),
        6379: Service(category: .cache, name: "Redis", iconName: "redis"),
        6380: Service(category: .cache, name: "Redis", iconName: "redis"),
        7000: Service(category: .development, name: "Development service"),
        8000: Service(category: .web, name: "Web server"),
        8001: Service(category: .web, name: "Web server"),
        8080: Service(category: .web, name: "HTTP alternate"),
        8081: Service(category: .web, name: "HTTP alternate"),
        8443: Service(category: .web, name: "HTTPS alternate"),
        8888: Service(category: .web, name: "Web server"),
        9000: Service(category: .web, name: "Development server"),
        9092: Service(category: .messaging, name: "Kafka", iconName: "kafka"),
        9200: Service(category: .database, name: "Elasticsearch", iconName: "elasticsearch"),
        9300: Service(category: .database, name: "Elasticsearch transport", iconName: "elasticsearch"),
        11211: Service(category: .cache, name: "Memcached"),
        15672: Service(category: .messaging, name: "RabbitMQ management"),
        27017: Service(category: .database, name: "MongoDB", iconName: "mongodb"),
        27018: Service(category: .database, name: "MongoDB", iconName: "mongodb"),
        27019: Service(category: .database, name: "MongoDB", iconName: "mongodb")
    ]

    private static let candidateWebPortRanges: [ClosedRange<Int>] = [
        3000...3999, 4200...4299, 5000...5001, 5173...5179, 8000...8999
    ]

    private static let candidateDevelopmentPortRanges: [ClosedRange<Int>] = [
        3000...10999
    ]

    public static func classify(_ entry: PortEntry) -> PortClassification {
        let processName = normalizedProcessName(entry.processName)

        if excludedProcessNames.contains(processName) {
            return PortClassification(
                category: .system,
                displayName: "macOS service",
                reason: "Known macOS background process"
            )
        }

        if isKnownToolingHelper(entry.executablePath) {
            return PortClassification(
                category: .other,
                displayName: "Editor helper",
                reason: "Internal editor or coding-assistant service"
            )
        }

        if isSystemExecutable(entry.executablePath) {
            return PortClassification(
                category: .system,
                displayName: "macOS service",
                reason: "Executable is part of macOS"
            )
        }

        let contextService = serviceFromExecutionContext(entry)
        let processService = contextService ?? service(forProcessName: processName)

        if isElixirRuntime(processName), isCandidateWebPort(entry.port) {
            return PortClassification(
                category: .web,
                displayName: "Phoenix / Elixir",
                reason: "BEAM runtime listening on a common web port",
                iconName: "phoenix"
            )
        }

        // A process name is stronger evidence than a conventional port. For example,
        // PostgreSQL listening on 8080 is still a database, not a web server.
        if let service = processService, service.category != .development {
            return PortClassification(
                category: service.category,
                displayName: service.name,
                reason: classificationReason(for: entry, fallback: "Recognized process: \(entry.processName)"),
                iconName: service.iconName
            )
        }

        if let processService,
           processService.category == .development,
           isCandidateWebPort(entry.port) {
            if let portService = knownServices[entry.port], portService.iconName != nil {
                return PortClassification(
                    category: .web,
                    displayName: portService.name,
                    reason: "Recognized runtime on known web port: \(entry.port)",
                    iconName: portService.iconName
                )
            }

            return PortClassification(
                category: .web,
                displayName: webServerName(for: processService),
                reason: classificationReason(
                    for: entry,
                    fallback: "Recognized runtime on common web port: \(entry.port)"
                ),
                iconName: processService.iconName
            )
        }

        if let service = knownServices[entry.port] {
            return PortClassification(
                category: service.category,
                displayName: service.name,
                reason: "Known service port: \(entry.port)",
                iconName: service.iconName
            )
        }

        if let service = processService {
            return PortClassification(
                category: service.category,
                displayName: service.name,
                reason: classificationReason(
                    for: entry,
                    fallback: "Recognized development process: \(entry.processName)"
                ),
                iconName: service.iconName
            )
        }

        if isBundledApplicationHelper(entry.executablePath) {
            return PortClassification(
                category: .other,
                displayName: "App helper",
                reason: "Listener belongs to a bundled macOS application"
            )
        }

        if let userID = entry.userID, userID < 500 {
            return PortClassification(
                category: .other,
                displayName: "Background service",
                reason: "Listener is owned by a system service account"
            )
        }

        if candidateWebPortRanges.contains(where: { $0.contains(entry.port) }) {
            return PortClassification(
                category: .web,
                displayName: "Possible web server",
                reason: "Common local web port range"
            )
        }

        if candidateDevelopmentPortRanges.contains(where: { $0.contains(entry.port) }) {
            return PortClassification(
                category: .development,
                displayName: "Possible dev service",
                reason: "Common development port range"
            )
        }

        return PortClassification(
            category: .other,
            displayName: "Other service",
            reason: "No known development signal"
        )
    }

    public static func includes(_ entry: PortEntry) -> Bool {
        classify(entry).isDevelopmentRelated
    }

    public static func includesWebServer(_ entry: PortEntry) -> Bool {
        classify(entry).isWebServer
    }

    private static func normalizedProcessName(_ processName: String) -> String {
        URL(fileURLWithPath: processName).lastPathComponent.lowercased()
    }

    private static func isCandidateWebPort(_ port: Int) -> Bool {
        knownServices[port]?.category == .web
            || candidateWebPortRanges.contains(where: { $0.contains(port) })
    }

    private static func isElixirRuntime(_ processName: String) -> Bool {
        ["beam.smp", "elixir", "iex", "mix"].contains(processName)
    }

    private static func serviceFromExecutionContext(_ entry: PortEntry) -> Service? {
        let executablePath = entry.executablePath?.lowercased() ?? ""
        let ancestorPaths = entry.ancestorExecutablePaths.map { $0.lowercased() }
        let ancestorNames = ancestorPaths.map(normalizedProcessName)

        if executablePath.contains("/target/debug/")
            || executablePath.contains("/target/release/")
            || ancestorNames.contains("cargo") {
            return Service(category: .development, name: "Rust application", iconName: "rust")
        }

        if executablePath.contains("/go-build/") || ancestorNames.contains("go") {
            return Service(category: .development, name: "Go application", iconName: "go")
        }

        if executablePath.contains("/.build/")
            && ancestorNames.contains(where: { ["swift", "swift-run", "swift-build"].contains($0) }) {
            return Service(category: .development, name: "Swift application", iconName: "swift")
        }

        if executablePath.contains("/node_modules/") {
            return Service(category: .development, name: "Node.js application", iconName: "node")
        }

        if executablePath.contains("/.venv/")
            || executablePath.contains("/venv/")
            || executablePath.contains("/virtualenvs/") {
            return Service(category: .development, name: "Python application", iconName: "python")
        }

        return nil
    }

    private static func isKnownToolingHelper(_ executablePath: String?) -> Bool {
        guard let path = executablePath?.lowercased() else {
            return false
        }

        let markers = [
            "/application support/zed/external_agents/",
            "/.local/share/uv/tools/serena-agent/",
            "/codex-acp/",
            "/visual studio code.app/contents/resources/app/extensions/",
            "/cursor.app/contents/resources/app/extensions/",
            "/dia.app/contents/resources/agent-server-resources/",
            "/figmaagent.app/contents/"
        ]

        return markers.contains(where: path.contains)
    }

    private static func isSystemExecutable(_ executablePath: String?) -> Bool {
        guard let path = executablePath?.lowercased() else {
            return false
        }

        return path.hasPrefix("/system/library/") || path.hasPrefix("/usr/libexec/")
    }

    private static func isBundledApplicationHelper(_ executablePath: String?) -> Bool {
        executablePath?.lowercased().contains(".app/contents/") == true
    }

    private static func webServerName(for service: Service) -> String {
        switch service.iconName {
        case "python": "Python web server"
        case "node": "Node.js web server"
        case "rust": "Rust web server"
        case "go": "Go web server"
        case "ruby", "rails": "Ruby web server"
        case "java", "spring": "Java web server"
        case "dotnet": ".NET web server"
        case "php": "PHP web server"
        case "bun": "Bun web server"
        case "deno": "Deno web server"
        case "swift": "Swift web server"
        case "dart", "flutter": "Dart web server"
        default: "Development web server"
        }
    }

    private static func classificationReason(for entry: PortEntry, fallback: String) -> String {
        guard let executablePath = entry.executablePath else {
            return fallback
        }

        if executablePath.lowercased().contains("/target/") {
            return "Rust target executable: \(URL(fileURLWithPath: executablePath).lastPathComponent)"
        }

        if entry.ancestorExecutablePaths.map(normalizedProcessName).contains("cargo") {
            return "Parent process ancestry includes Cargo"
        }

        return "Executable: \(URL(fileURLWithPath: executablePath).lastPathComponent)"
    }

    private static func service(forProcessName processName: String) -> Service? {
        switch processName {
        case "nginx":
            return Service(category: .web, name: "Nginx", iconName: "nginx")
        case "httpd", "apache2":
            return Service(category: .web, name: "Apache", iconName: "apache")
        case "caddy":
            return Service(category: .web, name: "Caddy", iconName: "caddy")
        case "vite", "next":
            return Service(category: .web, name: "JavaScript web server", iconName: "vite")
        case "gunicorn", "uvicorn", "puma":
            return Service(category: .web, name: "Application server", iconName: processName == "puma" ? "ruby" : "python")
        case "postgres", "postmaster":
            return Service(category: .database, name: "PostgreSQL", iconName: "postgresql")
        case "mysqld", "mariadbd":
            return Service(category: .database, name: "MySQL/MariaDB", iconName: processName == "mariadbd" ? "mariadb" : "mysql")
        case "mongod":
            return Service(category: .database, name: "MongoDB", iconName: "mongodb")
        case "redis-server", "memcached":
            return Service(category: .cache, name: "Cache server", iconName: processName == "redis-server" ? "redis" : nil)
        case "docker", "dockerd", "com.docker.backend", "colima":
            return Service(category: .container, name: "Container service", iconName: "docker")
        case "adb":
            return Service(category: .mobile, name: "Android Debug Bridge", iconName: "android")
        case "node", "nodejs", "npm", "npx", "pnpm", "yarn":
            return Service(category: .development, name: "Node.js runtime", iconName: "node")
        case "bun":
            return Service(category: .development, name: "Bun runtime", iconName: "bun")
        case "deno":
            return Service(category: .development, name: "Deno runtime", iconName: "deno")
        case "java":
            return Service(category: .development, name: "Java runtime", iconName: "java")
        case "dotnet":
            return Service(category: .development, name: ".NET runtime", iconName: "dotnet")
        case "go", "air":
            return Service(category: .development, name: "Go runtime", iconName: "go")
        case "cargo":
            return Service(category: .development, name: "Rust runtime", iconName: "rust")
        case "ruby":
            return Service(category: .development, name: "Ruby runtime", iconName: "ruby")
        case "rails":
            return Service(category: .development, name: "Rails server", iconName: "rails")
        case "php", "php-fpm":
            return Service(category: .development, name: "PHP runtime", iconName: "php")
        case "gradle":
            return Service(category: .development, name: "Gradle", iconName: "gradle")
        case "spring":
            return Service(category: .development, name: "Spring", iconName: "spring")
        case "swift", "swift-run", "swift-build":
            return Service(category: .development, name: "Swift runtime", iconName: "swift")
        case "kubectl":
            return Service(category: .container, name: "Kubernetes port forward", iconName: "kubernetes")
        case "dart":
            return Service(category: .development, name: "Dart runtime", iconName: "dart")
        case "flutter":
            return Service(category: .development, name: "Flutter tool", iconName: "flutter")
        case "beam.smp", "elixir", "iex", "mix":
            return Service(category: .development, name: "Elixir / Erlang runtime", iconName: "elixir")
        case "epmd":
            return Service(category: .development, name: "Erlang Port Mapper", iconName: "elixir")
        default:
            if processName.hasPrefix("python") {
                return Service(category: .development, name: "Python runtime", iconName: "python")
            }
            if processName.hasPrefix("ruby") {
                return Service(category: .development, name: "Ruby runtime", iconName: "ruby")
            }
            if processName.hasPrefix("php") {
                return Service(category: .development, name: "PHP runtime", iconName: "php")
            }

            return nil
        }
    }
}
