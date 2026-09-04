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

    func testDoesNotUseRiskySubstringMatchingForShortRuntimeNames() {
        XCTAssertFalse(
            DevelopmentPortFilter.includes(
                entry(processName: "goggles-helper", port: 44_438)
            )
        )

        XCTAssertFalse(
            DevelopmentPortFilter.includes(
                entry(processName: "airport-helper", port: 44_439)
            )
        )
    }

    func testRecognizesVersionedPythonAsDevelopmentRuntime() {
        let classification = DevelopmentPortFilter.classify(
            entry(processName: "python3.13", port: 24_282)
        )

        XCTAssertEqual(classification.category, .development)
        XCTAssertEqual(classification.displayName, "Python runtime")
        XCTAssertEqual(classification.iconName, "python")
    }

    func testGenericRuntimeNeedsAWebPortToAppearInWebFilter() {
        let highNodePort = entry(processName: "node", port: 24_283)
        let vitePort = entry(processName: "node", port: 5173)

        XCTAssertTrue(DevelopmentPortFilter.includes(highNodePort))
        XCTAssertFalse(DevelopmentPortFilter.includesWebServer(highNodePort))
        XCTAssertTrue(DevelopmentPortFilter.includesWebServer(vitePort))
        XCTAssertEqual(DevelopmentPortFilter.classify(vitePort).displayName, "Vite")
        XCTAssertEqual(DevelopmentPortFilter.classify(vitePort).iconName, "vite")
    }

    func testProcessRoleWinsWhenPortUsuallyMeansWeb() {
        let entry = entry(processName: "postgres", port: 8080)

        XCTAssertFalse(DevelopmentPortFilter.includesWebServer(entry))
        XCTAssertEqual(DevelopmentPortFilter.classify(entry).category, .database)
    }

    func testClassifiesKnownServicesWithUsefulNames() {
        XCTAssertEqual(
            DevelopmentPortFilter.classify(entry(processName: "cadb", port: 5037)).displayName,
            "Android Debug Bridge"
        )
        XCTAssertEqual(
            DevelopmentPortFilter.classify(entry(processName: "cadb", port: 5037)).iconName,
            "android"
        )
        XCTAssertEqual(
            DevelopmentPortFilter.classify(entry(processName: "custom-api", port: 5173)).displayName,
            "Vite"
        )
        XCTAssertEqual(
            DevelopmentPortFilter.classify(entry(processName: "custom-db", port: 5432)).displayName,
            "PostgreSQL"
        )
    }

    func testRecognizesElixirBeamRuntime() {
        let classification = DevelopmentPortFilter.classify(
            entry(processName: "beam.smp", port: 24_290)
        )

        XCTAssertEqual(classification.category, .development)
        XCTAssertEqual(classification.displayName, "Elixir / Erlang runtime")
        XCTAssertEqual(classification.iconName, "elixir")
    }

    func testRecognizesPhoenixRunningOnBeam() {
        let classification = DevelopmentPortFilter.classify(
            entry(processName: "beam.smp", port: 4000)
        )

        XCTAssertEqual(classification.category, .web)
        XCTAssertEqual(classification.displayName, "Phoenix / Elixir")
        XCTAssertEqual(classification.iconName, "phoenix")
    }

    func testRecognizesErlangPortMapper() {
        let classification = DevelopmentPortFilter.classify(
            entry(processName: "epmd", port: 4369)
        )

        XCTAssertEqual(classification.category, .development)
        XCTAssertEqual(classification.displayName, "Erlang Port Mapper")
        XCTAssertEqual(classification.iconName, "elixir")
    }

    func testRecognizesCompiledRustExecutableByTargetPath() {
        let classification = DevelopmentPortFilter.classify(
            entry(
                processName: "my-api",
                port: 24_300,
                executablePath: "/Users/dev/project/target/debug/my-api"
            )
        )

        XCTAssertEqual(classification.category, .development)
        XCTAssertEqual(classification.displayName, "Rust application")
        XCTAssertEqual(classification.iconName, "rust")
    }

    func testRecognizesRustWebServerByCargoAncestry() {
        let classification = DevelopmentPortFilter.classify(
            entry(
                processName: "my-api",
                port: 3000,
                executablePath: "/Users/dev/bin/my-api",
                ancestorExecutablePaths: ["/Users/dev/.cargo/bin/cargo", "/bin/zsh"]
            )
        )

        XCTAssertEqual(classification.category, .web)
        XCTAssertEqual(classification.displayName, "Rust web server")
        XCTAssertEqual(classification.iconName, "rust")
    }

    func testHidesCodingAssistantPythonListener() {
        let entry = entry(
            processName: "python3.13",
            port: 24_282,
            executablePath: "/Users/dev/.local/share/uv/tools/serena-agent/bin/python"
        )

        XCTAssertFalse(DevelopmentPortFilter.includes(entry))
        XCTAssertEqual(DevelopmentPortFilter.classify(entry).displayName, "Editor helper")
    }

    func testRuntimeIdentityIsPreservedOnGenericWebPort() {
        let classification = DevelopmentPortFilter.classify(
            entry(processName: "python3.13", port: 8000)
        )

        XCTAssertEqual(classification.category, .web)
        XCTAssertEqual(classification.displayName, "Python web server")
        XCTAssertEqual(classification.iconName, "python")
    }

    func testSystemExecutableDoesNotBecomeWebServerFromPortAlone() {
        let entry = entry(
            processName: "new-system-helper",
            port: 5173,
            executablePath: "/System/Library/PrivateFrameworks/NewService"
        )

        XCTAssertFalse(DevelopmentPortFilter.includes(entry))
        XCTAssertEqual(DevelopmentPortFilter.classify(entry).category, .system)
    }

    func testGenericRuntimeOnCandidateWebRangeBecomesWebServer() {
        let classification = DevelopmentPortFilter.classify(
            entry(processName: "node", port: 3334)
        )

        XCTAssertEqual(classification.category, .web)
        XCTAssertEqual(classification.displayName, "Node.js web server")
        XCTAssertEqual(classification.iconName, "node")
    }

    func testRecognizesSwiftPMExecutableFromAncestry() {
        let classification = DevelopmentPortFilter.classify(
            entry(
                processName: "api",
                port: 8080,
                executablePath: "/Users/dev/api/.build/arm64-apple-macosx/debug/api",
                ancestorExecutablePaths: ["/usr/bin/swift-run", "/bin/zsh"]
            )
        )

        XCTAssertEqual(classification.category, .web)
        XCTAssertEqual(classification.displayName, "Swift web server")
        XCTAssertEqual(classification.iconName, "swift")
    }

    func testRecognizesKubernetesPortForward() {
        let classification = DevelopmentPortFilter.classify(
            entry(processName: "kubectl", port: 54_321)
        )

        XCTAssertEqual(classification.category, .container)
        XCTAssertEqual(classification.displayName, "Kubernetes port forward")
        XCTAssertEqual(classification.iconName, "kubernetes")
    }

    private func entry(
        processName: String,
        port: Int,
        executablePath: String? = nil,
        ancestorExecutablePaths: [String] = []
    ) -> PortEntry {
        PortEntry(
            processName: processName,
            pid: 123,
            port: port,
            protocolName: "TCP",
            endpoint: "127.0.0.1:\(port)",
            executablePath: executablePath,
            ancestorExecutablePaths: ancestorExecutablePaths
        )
    }
}
