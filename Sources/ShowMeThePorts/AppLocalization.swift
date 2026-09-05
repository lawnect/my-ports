import Foundation
import ShowMeThePortsCore

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
    static var settings: String { string("action.settings") }
    static var cancel: String { string("action.cancel") }
    static var terminate: String { string("action.terminate") }
    static var ok: String { string("action.ok") }
    static var filter: String { string("label.filter") }
    static var port: String { string("label.port") }
    static var searchPlaceholder: String { string("search.placeholder") }
    static var clear: String { string("action.clear") }
    static var lookingForPorts: String { string("status.looking_for_ports") }
    static var quit: String { string("action.quit") }
    static var refreshing: String { string("status.refreshing") }
    static var notRefreshed: String { string("status.not_refreshed") }
    static var noMatchingPorts: String { string("empty.no_matches") }
    static var noWebPorts: String { string("empty.no_web_ports") }
    static var noDevelopmentPorts: String { string("empty.no_development_ports") }
    static var noListeningPorts: String { string("empty.no_listening_ports") }
    static var launchAtLogin: String { string("setting.launch_at_login") }
    static var launchAtLoginRequiresApproval: String {
        string("status.launch_at_login_requires_approval")
    }
    static var terminateProcessTitle: String { string("confirmation.kill.title") }
    static var protectedProcessTitle: String { string("protected.title") }

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

    static func protectedProcessHelp(processName: String, pid: Int32) -> String {
        format("action.protected_process", localizedProcessName(processName), Int64(pid))
    }

    static func protectedProcessMessage(
        processName: String,
        pid: Int32,
        reason: ProcessProtectionReason
    ) -> String {
        format(
            "protected.message",
            localizedProcessName(processName),
            Int64(pid),
            protectionReason(reason)
        )
    }

    static func protectionReason(_ reason: ProcessProtectionReason) -> String {
        switch reason {
        case .coreSystemProcess: string("protected.reason.core_system")
        case .currentApplication: string("protected.reason.current_application")
        case .macOSService: string("protected.reason.macos_service")
        case .unknownOwner: string("protected.reason.unknown_owner")
        case .administratorOwned: string("protected.reason.administrator_owned")
        case .anotherUser: string("protected.reason.another_user")
        }
    }

    static func launchAtLoginError(_ message: String) -> String {
        format("error.launch_at_login", message)
    }

    static func terminateProcessMessage(
        processName: String,
        pid: Int32,
        port: Int
    ) -> String {
        format(
            "confirmation.kill.message",
            localizedProcessName(processName),
            Int64(pid),
            Int64(port)
        )
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
