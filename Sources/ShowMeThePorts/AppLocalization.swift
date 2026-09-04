import Foundation

enum AppResources {
    static var bundle: Bundle {
        #if SWIFT_PACKAGE
        Bundle.module
        #else
        Bundle.main
        #endif
    }
}

enum L10n {
    static var appName: String { string("app.name") }
    static var refresh: String { string("action.refresh") }
    static var filter: String { string("label.filter") }
    static var port: String { string("label.port") }
    static var clear: String { string("action.clear") }
    static var lookingForPorts: String { string("status.looking_for_ports") }
    static var quit: String { string("action.quit") }
    static var refreshing: String { string("status.refreshing") }
    static var notRefreshed: String { string("status.not_refreshed") }
    static var noMatchingPorts: String { string("empty.no_matches") }
    static var noWebPorts: String { string("empty.no_web_ports") }
    static var noDevelopmentPorts: String { string("empty.no_development_ports") }
    static var noListeningPorts: String { string("empty.no_listening_ports") }

    static func filterName(_ mode: PortFilterMode) -> String {
        switch mode {
        case .web: string("filter.web")
        case .development: string("filter.development")
        case .all: string("filter.all")
        }
    }

    static func updated(at time: String) -> String {
        format("status.updated", time)
    }

    static func pid(_ pid: Int32) -> String {
        format("process.pid", Int64(pid))
    }

    static func killHelp(processName: String, pid: Int32) -> String {
        format("action.kill_process", localizedProcessName(processName), Int64(pid))
    }

    static func localizedProcessName(_ processName: String) -> String {
        processName == "Unknown" ? string("process.unknown") : processName
    }

    static func classificationName(_ name: String) -> String {
        string("classification.name.\(name)", fallback: name)
    }

    static func classificationReason(_ reason: String) -> String {
        let dynamicReasons = [
            ("Recognized process: ", "classification.reason.recognized_process"),
            ("Recognized runtime on known web port: ", "classification.reason.runtime_known_web_port"),
            ("Recognized runtime on common web port: ", "classification.reason.runtime_common_web_port"),
            ("Known service port: ", "classification.reason.known_service_port"),
            ("Recognized development process: ", "classification.reason.recognized_development_process"),
            ("Rust target executable: ", "classification.reason.rust_target_executable"),
            ("Executable: ", "classification.reason.executable")
        ]

        for (prefix, key) in dynamicReasons where reason.hasPrefix(prefix) {
            return format(key, String(reason.dropFirst(prefix.count)))
        }

        return string("classification.reason.\(reason)", fallback: reason)
    }

    static func string(_ key: String, fallback: String? = nil) -> String {
        AppResources.bundle.localizedString(forKey: key, value: fallback, table: nil)
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(
            format: string(key),
            locale: Locale.current,
            arguments: arguments
        )
    }
}
