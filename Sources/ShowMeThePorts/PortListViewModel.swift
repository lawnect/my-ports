import Foundation
import ShowMeThePortsCore

enum PortFilterMode: CaseIterable, Identifiable {
    case all
    case web
    case development

    var id: Self { self }

    var displayName: String {
        L10n.filterName(self)
    }
}

@MainActor
final class PortListViewModel: ObservableObject {
    @Published private var allPorts: [PortEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var killingPIDs = Set<Int32>()
    @Published var filterMode: PortFilterMode = .all
    @Published var portSearchText = ""
    @Published var errorMessage: String?

    private let scanner: LsofPortScanner
    private let killer: ProcessPortKiller
    private var lastUpdated: Date?
    private var isRefreshing = false

    init(
        scanner: LsofPortScanner = LsofPortScanner(),
        killer: ProcessPortKiller = ProcessPortKiller()
    ) {
        self.scanner = scanner
        self.killer = killer
    }

    var ports: [PortEntry] {
        let filteredPorts: [PortEntry]

        switch filterMode {
        case .web:
            filteredPorts = allPorts.filter(DevelopmentPortFilter.includesWebServer)
        case .development:
            filteredPorts = allPorts.filter(DevelopmentPortFilter.includes)
        case .all:
            filteredPorts = allPorts
        }

        let searchText = normalizedPortSearchText

        guard !searchText.isEmpty else {
            return filteredPorts
        }

        return filteredPorts.filter { entry in
            matchesSearch(entry, query: searchText)
        }
    }

    var availableFilterModes: [PortFilterMode] {
        var modes: [PortFilterMode] = [.all]

        if allPorts.contains(where: { $0.classification.isWebServer }) {
            modes.append(.web)
        }

        if allPorts.contains(where: { entry in
            let classification = entry.classification
            return classification.isDevelopmentRelated && !classification.isWebServer
        }) {
            modes.append(.development)
        }

        return modes
    }

    var showsFilterPicker: Bool {
        availableFilterModes.count > 1
    }

    var footerStatus: String {
        guard let lastUpdated else {
            return L10n.notRefreshed
        }

        let updatedText = L10n.updated(
            at: lastUpdated.formatted(date: .omitted, time: .standard)
        )
        let searchText = normalizedPortSearchText
        let detail: String?

        switch filterMode {
        case .web:
            let hiddenCount = max(allPorts.count - ports.count, 0)

            if !searchText.isEmpty {
                detail = L10n.format("status.web_matches", Int64(ports.count))
            } else if hiddenCount == 0 {
                detail = L10n.format("status.web_count", Int64(ports.count))
            } else {
                detail = L10n.format(
                    "status.web_hidden",
                    Int64(ports.count),
                    Int64(hiddenCount)
                )
            }
        case .development:
            let hiddenCount = max(allPorts.count - ports.count, 0)

            if !searchText.isEmpty {
                detail = L10n.format("status.development_matches", Int64(ports.count))
            } else if hiddenCount == 0 {
                detail = L10n.format("status.development_count", Int64(ports.count))
            } else {
                detail = L10n.format(
                    "status.development_hidden",
                    Int64(ports.count),
                    Int64(hiddenCount)
                )
            }
        case .all:
            if !searchText.isEmpty {
                detail = L10n.format("status.all_matches", Int64(ports.count))
            } else {
                detail = nil
            }
        }

        guard let detail else {
            return updatedText
        }

        return "\(updatedText) · \(detail)"
    }

    var emptyStateMessage: String {
        if !normalizedPortSearchText.isEmpty {
            return L10n.noMatchingPorts
        }

        switch filterMode {
        case .web:
            return L10n.noWebPorts
        case .development:
            return L10n.noDevelopmentPorts
        case .all:
            return L10n.noListeningPorts
        }
    }

    private var normalizedPortSearchText: String {
        portSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func matchesSearch(_ entry: PortEntry, query: String) -> Bool {
        let classification = entry.classification
        var searchableValues = [
            String(entry.port),
            String(entry.pid),
            entry.processName,
            L10n.localizedProcessName(entry.processName),
            entry.protocolName,
            entry.endpoint,
            classification.displayName,
            L10n.classificationName(classification.displayName),
            classification.reason,
            L10n.classificationReason(classification.reason)
        ]

        if let parentPID = entry.parentPID {
            searchableValues.append(String(parentPID))
        }

        if let userID = entry.userID {
            searchableValues.append(String(userID))
        }

        if let executablePath = entry.executablePath {
            searchableValues.append(executablePath)
        }

        searchableValues.append(contentsOf: entry.ancestorExecutablePaths)
        let searchableText = searchableValues.joined(separator: "\n")
        let terms = query.split(whereSeparator: \.isWhitespace)

        return terms.allSatisfy { term in
            searchableText.localizedCaseInsensitiveContains(String(term))
        }
    }

    func refresh(showsActivity: Bool = true) async {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true

        if showsActivity {
            isLoading = true
        }

        errorMessage = nil
        defer {
            isRefreshing = false

            if showsActivity {
                isLoading = false
            }
        }

        do {
            allPorts = try await scanner.listeningPorts()

            if !availableFilterModes.contains(filterMode) {
                filterMode = .all
            }

            lastUpdated = Date()
        } catch {
            errorMessage = error.localizedDescription
        }

    }

    func kill(_ entry: PortEntry) async {
        killingPIDs.insert(entry.pid)
        errorMessage = nil

        do {
            try await killer.kill(pid: entry.pid)
            try? await Task.sleep(for: .milliseconds(200))
        } catch {
            errorMessage = error.localizedDescription
        }

        killingPIDs.remove(entry.pid)
        await refresh()
    }
}
