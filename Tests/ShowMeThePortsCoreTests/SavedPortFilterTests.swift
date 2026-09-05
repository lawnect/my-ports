import XCTest
@testable import ShowMeThePortsCore

final class SavedPortFilterTests: XCTestCase {
    func testDevelopmentPresetIncludesWebAndDevelopmentTools() {
        let filter = SavedPortFilter.development()

        XCTAssertTrue(filter.matches(entry(processName: "node", port: 5173), currentUserID: 501, currentProcessID: 999))
        XCTAssertTrue(filter.matches(entry(processName: "adb", port: 5037), currentUserID: 501, currentProcessID: 999))
        XCTAssertFalse(filter.matches(entry(processName: "rapportd", port: 55_000), currentUserID: 501, currentProcessID: 999))
    }

    func testCombinesCategoryOwnershipExposureAndPortRange() {
        let filter = SavedPortFilter(
            name: "Local web",
            categories: [.web],
            ownership: .currentUser,
            exposure: .localOnly,
            minimumPort: 3000,
            maximumPort: 5999
        )

        XCTAssertTrue(filter.matches(entry(processName: "node", port: 5173), currentUserID: 501, currentProcessID: 999))
        XCTAssertFalse(filter.matches(entry(processName: "node", port: 8000), currentUserID: 501, currentProcessID: 999))
        XCTAssertFalse(filter.matches(entry(processName: "node", port: 5173, endpoint: "*:5173"), currentUserID: 501, currentProcessID: 999))
        XCTAssertFalse(filter.matches(entry(processName: "node", port: 5173, userID: 502), currentUserID: 501, currentProcessID: 999))
    }

    func testFiltersByTerminationProtection() {
        let protectedFilter = SavedPortFilter(name: "Protected", termination: .protected)
        let terminableFilter = SavedPortFilter(name: "Terminable", termination: .terminable)
        let systemEntry = entry(processName: "ControlCenter", port: 5000)
        let userEntry = entry(processName: "node", port: 5173)

        XCTAssertTrue(protectedFilter.matches(systemEntry, currentUserID: 501, currentProcessID: 999))
        XCTAssertFalse(protectedFilter.matches(userEntry, currentUserID: 501, currentProcessID: 999))
        XCTAssertTrue(terminableFilter.matches(userEntry, currentUserID: 501, currentProcessID: 999))
        XCTAssertFalse(terminableFilter.matches(systemEntry, currentUserID: 501, currentProcessID: 999))
    }

    func testMatchesProcessAndAncestorTerms() {
        let filter = SavedPortFilter(name: "Codex Serena", processQuery: "codex serena")
        let port = entry(
            processName: "python3.13",
            port: 24_282,
            executablePath: "/Users/dev/.local/share/uv/tools/serena-agent/bin/python",
            ancestorExecutablePaths: ["/Users/dev/codex-acp/bin/codex"]
        )

        XCTAssertTrue(filter.matches(port, currentUserID: 501, currentProcessID: 999))
    }

    func testCodableRoundTripPreservesRules() throws {
        let original = SavedPortFilter(
            name: "Infrastructure",
            categories: [.database, .cache, .container],
            ownership: .currentUser,
            termination: .terminable,
            exposure: .networkVisible,
            processQuery: "docker",
            minimumPort: 2000,
            maximumPort: 9000,
            isPinned: false
        )

        let data = try JSONEncoder().encode(original)
        XCTAssertEqual(try JSONDecoder().decode(SavedPortFilter.self, from: data), original)
    }

    private func entry(
        processName: String,
        port: Int,
        endpoint: String? = nil,
        userID: UInt32? = 501,
        executablePath: String? = nil,
        ancestorExecutablePaths: [String] = []
    ) -> PortEntry {
        PortEntry(
            processName: processName,
            pid: 123,
            port: port,
            protocolName: "TCP",
            endpoint: endpoint ?? "127.0.0.1:\(port)",
            userID: userID,
            executablePath: executablePath,
            ancestorExecutablePaths: ancestorExecutablePaths
        )
    }
}
