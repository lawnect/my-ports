import Foundation
import ShowMeThePortsCore

enum PortFilterMode: CaseIterable, Identifiable {
    case web
    case development
    case all

    var id: Self { self }

    var displayName: String {
        L10n.filterName(self)
    }
}

@MainActor
final class PortListViewModel: ObservableObject {
    @Published private(set) var ports: [PortEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var killingPIDs = Set<Int32>()
    @Published var filterMode: PortFilterMode = .web {
        didSet {
            applyFilter()
        }
    }
    @Published var portSearchText = "" {
        didSet {
            applyFilter()
        }
    }
    @Published var errorMessage: String?

    private let scanner: LsofPortScanner
    private let killer: ProcessPortKiller
    private var allPorts: [PortEntry] = []
    private var lastUpdated: Date?

    init(
        scanner: LsofPortScanner = LsofPortScanner(),
        killer: ProcessPortKiller = ProcessPortKiller()
    ) {
        self.scanner = scanner
        self.killer = killer
    }

    var footerStatus: String {
        if isLoading {
            return L10n.refreshing
        }

        guard let lastUpdated else {
            return L10n.notRefreshed
        }

        let updatedText = L10n.updated(
            at: lastUpdated.formatted(date: .omitted, time: .standard)
        )
        let searchText = normalizedPortSearchText
        let detail: String

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
                detail = L10n.format("status.all_total", Int64(allPorts.count))
            }
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

    func refresh() async {
        isLoading = true
        errorMessage = nil

        do {
            allPorts = try await scanner.listeningPorts()
            applyFilter()
            lastUpdated = Date()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
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

    private func applyFilter() {
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

        if searchText.isEmpty {
            ports = filteredPorts
        } else {
            ports = filteredPorts.filter { String($0.port).contains(searchText) }
        }
    }
}
