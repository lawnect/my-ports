import Foundation
import ShowMeThePortsCore

enum PortFilterMode: String, CaseIterable, Identifiable {
    case web = "Web"
    case development = "Dev"
    case all = "All"

    var id: Self { self }
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
            return "Refreshing..."
        }

        guard let lastUpdated else {
            return "Not refreshed yet"
        }

        let updatedText = "Updated \(lastUpdated.formatted(date: .omitted, time: .standard))"
        let searchText = normalizedPortSearchText

        switch filterMode {
        case .web:
            let hiddenCount = max(allPorts.count - ports.count, 0)

            if !searchText.isEmpty {
                return "\(updatedText) · \(ports.count) web matches"
            }

            if hiddenCount == 0 {
                return "\(updatedText) · \(ports.count) web"
            }

            return "\(updatedText) · \(ports.count) web · \(hiddenCount) hidden"
        case .development:
            let hiddenCount = max(allPorts.count - ports.count, 0)

            if !searchText.isEmpty {
                return "\(updatedText) · \(ports.count) dev matches"
            }

            if hiddenCount == 0 {
                return "\(updatedText) · \(ports.count) dev"
            }

            return "\(updatedText) · \(ports.count) dev · \(hiddenCount) hidden"
        case .all:
            if !searchText.isEmpty {
                return "\(updatedText) · \(ports.count) matches"
            }

            return "\(updatedText) · \(allPorts.count) total"
        }
    }

    var emptyStateMessage: String {
        if !normalizedPortSearchText.isEmpty {
            return "No matching ports"
        }

        switch filterMode {
        case .web:
            return "No web ports"
        case .development:
            return "No development ports"
        case .all:
            return "No listening ports"
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
