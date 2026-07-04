import XCTest
@testable import ShowMeThePortsCore

final class DevelopmentPortFilterTests: XCTestCase {
    func testIncludesCommonDevelopmentServer() {
        XCTAssertTrue(
            DevelopmentPortFilter.includes(
                entry(processName: "node", port: 3000)
            )
        )
    }

    func testIncludesProjectSpecificProcessOnCommonDevPort() {
        XCTAssertTrue(
            DevelopmentPortFilter.includes(
                entry(processName: "glb-api", port: 8080)
            )
        )
    }

    func testIncludesCommonDatabasePort() {
        XCTAssertTrue(
            DevelopmentPortFilter.includes(
                entry(processName: "mongod", port: 27017)
            )
        )
    }

    func testWebFilterIncludesCommonWebServer() {
        XCTAssertTrue(
            DevelopmentPortFilter.includesWebServer(
                entry(processName: "node", port: 5173)
            )
        )
    }

    func testWebFilterIncludesProjectWebApiPort() {
        XCTAssertTrue(
            DevelopmentPortFilter.includesWebServer(
                entry(processName: "glb-api", port: 8080)
            )
        )
    }

    func testWebFilterExcludesAndroidDebugBridge() {
        XCTAssertFalse(
            DevelopmentPortFilter.includesWebServer(
                entry(processName: "cadb", port: 5037)
            )
        )
    }

    func testWebFilterExcludesDatabasePort() {
        XCTAssertFalse(
            DevelopmentPortFilter.includesWebServer(
                entry(processName: "postgres", port: 5432)
            )
        )
    }

    func testExcludesKnownMacOSProcessOnCommonPort() {
        XCTAssertFalse(
            DevelopmentPortFilter.includes(
                entry(processName: "ControlCenter", port: 5000)
            )
        )
    }

    func testExcludesEditorInternalHighPort() {
        XCTAssertFalse(
            DevelopmentPortFilter.includes(
                entry(processName: "zed", port: 44438)
            )
        )
    }

    private func entry(processName: String, port: Int) -> PortEntry {
        PortEntry(
            processName: processName,
            pid: 123,
            port: port,
            protocolName: "TCP",
            endpoint: "127.0.0.1:\(port)"
        )
    }
}
