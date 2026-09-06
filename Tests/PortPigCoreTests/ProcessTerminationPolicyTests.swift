import XCTest
@testable import PortPigCore

final class ProcessTerminationPolicyTests: XCTestCase {
    func testAllowsCurrentUsersProcess() {
        XCTAssertNil(reason(pid: 100, userID: 501))
    }

    func testProtectsAdministratorOwnedProcess() {
        XCTAssertEqual(reason(pid: 100, userID: 0), .administratorOwned)
    }

    func testProtectsAnotherUsersProcess() {
        XCTAssertEqual(reason(pid: 100, userID: 502), .anotherUser)
    }

    func testProtectsUnknownOwner() {
        XCTAssertEqual(reason(pid: 100, userID: nil), .unknownOwner)
    }

    func testProtectsCurrentApplication() {
        XCTAssertEqual(reason(pid: 999, userID: 501), .currentApplication)
    }

    func testProtectsMacOSServiceOwnedByCurrentUser() {
        XCTAssertEqual(
            reason(pid: 100, userID: 501, processName: "ControlCenter", port: 5000),
            .macOSService
        )
    }

    private func reason(
        pid: Int32,
        userID: UInt32?,
        processName: String = "node",
        port: Int = 3000
    ) -> ProcessProtectionReason? {
        ProcessTerminationPolicy.protectionReason(
            for: PortEntry(
                processName: processName,
                pid: pid,
                port: port,
                protocolName: "TCP",
                endpoint: "127.0.0.1:\(port)",
                userID: userID
            ),
            currentUserID: 501,
            currentProcessID: 999
        )
    }
}
