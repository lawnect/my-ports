import Foundation

public enum PortOwnershipScope: String, CaseIterable, Codable, Sendable {
    case any
    case currentUser
    case administrator
    case otherOrUnknown
}

public enum PortTerminationScope: String, CaseIterable, Codable, Sendable {
    case any
    case terminable
    case protected
}

public enum PortExposureScope: String, CaseIterable, Codable, Sendable {
    case any
    case localOnly
    case networkVisible
}

public struct SavedPortFilter: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var categories: Set<PortCategory>
    public var ownership: PortOwnershipScope
    public var termination: PortTerminationScope
    public var exposure: PortExposureScope
    public var processQuery: String
    public var minimumPort: Int?
    public var maximumPort: Int?
    public var isPinned: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        categories: Set<PortCategory> = [],
        ownership: PortOwnershipScope = .any,
        termination: PortTerminationScope = .any,
        exposure: PortExposureScope = .any,
        processQuery: String = "",
        minimumPort: Int? = nil,
        maximumPort: Int? = nil,
        isPinned: Bool = true
    ) {
        self.id = id
        self.name = name
        self.categories = categories
        self.ownership = ownership
        self.termination = termination
        self.exposure = exposure
        self.processQuery = processQuery
        self.minimumPort = minimumPort
        self.maximumPort = maximumPort
        self.isPinned = isPinned
    }

    public static func development(name: String = "Dev") -> SavedPortFilter {
        SavedPortFilter(
            name: name,
            categories: Set(
                PortCategory.allCases.filter { category in
                    switch category {
                    case .web, .database, .cache, .messaging, .container, .mobile, .development:
                        true
                    case .system, .other:
                        false
                    }
                }
            )
        )
    }

    public func matches(
        _ entry: PortEntry,
        currentUserID: UInt32,
        currentProcessID: Int32
    ) -> Bool {
        if !categories.isEmpty, !categories.contains(entry.classification.category) {
            return false
        }

        if !matchesOwnership(entry, currentUserID: currentUserID) {
            return false
        }

        let isProtected = ProcessTerminationPolicy.protectionReason(
            for: entry,
            currentUserID: currentUserID,
            currentProcessID: currentProcessID
        ) != nil

        switch termination {
        case .any:
            break
        case .terminable where isProtected:
            return false
        case .protected where !isProtected:
            return false
        default:
            break
        }

        let isLocalOnly = Self.isLocalOnly(endpoint: entry.endpoint)

        switch exposure {
        case .any:
            break
        case .localOnly where !isLocalOnly:
            return false
        case .networkVisible where isLocalOnly:
            return false
        default:
            break
        }

        if let minimumPort, entry.port < minimumPort {
            return false
        }

        if let maximumPort, entry.port > maximumPort {
            return false
        }

        let query = processQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        if !query.isEmpty {
            let classification = entry.classification
            let searchableValues = [
                entry.processName,
                classification.displayName,
                entry.executablePath ?? ""
            ] + entry.ancestorExecutablePaths
            let searchableText = searchableValues.joined(separator: "\n")
            let terms = query.split(whereSeparator: \.isWhitespace)

            if !terms.allSatisfy({ term in
                searchableText.localizedCaseInsensitiveContains(String(term))
            }) {
                return false
            }
        }

        return true
    }

    private func matchesOwnership(_ entry: PortEntry, currentUserID: UInt32) -> Bool {
        switch ownership {
        case .any:
            true
        case .currentUser:
            entry.userID == currentUserID
        case .administrator:
            entry.userID == 0
        case .otherOrUnknown:
            entry.userID == nil || (entry.userID != currentUserID && entry.userID != 0)
        }
    }

    private static func isLocalOnly(endpoint: String) -> Bool {
        let endpoint = endpoint.lowercased()
        return endpoint.hasPrefix("127.0.0.1:")
            || endpoint.hasPrefix("[::1]:")
            || endpoint.hasPrefix("localhost:")
    }
}
