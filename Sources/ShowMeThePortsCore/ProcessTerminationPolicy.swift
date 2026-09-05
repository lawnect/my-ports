import Foundation

public enum ProcessProtectionReason: Equatable, Sendable {
    case coreSystemProcess
    case currentApplication
    case macOSService
    case unknownOwner
    case administratorOwned
    case anotherUser
}

public enum ProcessTerminationPolicy {
    public static func protectionReason(
        for entry: PortEntry,
        currentUserID: UInt32,
        currentProcessID: Int32
    ) -> ProcessProtectionReason? {
        if entry.pid <= 1 {
            return .coreSystemProcess
        }

        if entry.pid == currentProcessID {
            return .currentApplication
        }

        if entry.classification.category == .system {
            return .macOSService
        }

        guard let userID = entry.userID else {
            return .unknownOwner
        }

        if userID == 0 {
            return .administratorOwned
        }

        if userID != currentUserID {
            return .anotherUser
        }

        return nil
    }
}
