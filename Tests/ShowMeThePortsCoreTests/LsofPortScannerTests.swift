import XCTest
@testable import ShowMeThePortsCore

final class LsofPortScannerTests: XCTestCase {
    func testParseFieldOutputDeduplicatesRepeatedFileDescriptors() {
        let output = """
        p100
        cnode
        f10
        PTCP
        n*:3000
        f11
        PTCP
        n*:3000
        p200
        cpython3.13
        f4
        PTCP
        n127.0.0.1:8000
        """

        let ports = LsofPortScanner.parse(output)

        XCTAssertEqual(ports.count, 2)
        XCTAssertEqual(ports.map(\.port), [3000, 8000])
        XCTAssertEqual(ports[0].processName, "node")
        XCTAssertEqual(ports[0].pid, 100)
    }

    func testParseFieldOutputHandlesIPv6Endpoints() {
        let output = """
        p300
        cnode
        f31
        PTCP
        n[::1]:5273
        """

        let ports = LsofPortScanner.parse(output)

        XCTAssertEqual(ports.count, 1)
        XCTAssertEqual(ports[0].port, 5273)
        XCTAssertEqual(ports[0].endpoint, "[::1]:5273")
    }

    func testParseFieldOutputIgnoresMalformedPorts() {
        let output = """
        p400
        cservice
        f8
        PTCP
        n127.0.0.1:not-a-port
        """

        XCTAssertTrue(LsofPortScanner.parse(output).isEmpty)
    }
}
