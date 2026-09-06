import Combine
import ServiceManagement

@MainActor
final class LaunchAtLoginController: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var errorMessage: String?

    private let service = SMAppService.mainApp

    init() {
        isEnabled = service.status == .enabled
    }

    func refreshStatus() {
        isEnabled = service.status == .enabled
    }

    func setEnabled(_ shouldEnable: Bool) {
        Task { @MainActor [weak self] in
            await Task.yield()
            self?.updateRegistration(shouldEnable: shouldEnable)
        }
    }

    private func updateRegistration(shouldEnable: Bool) {
        errorMessage = nil

        do {
            if shouldEnable {
                if service.status == .requiresApproval {
                    errorMessage = L10n.launchAtLoginRequiresApproval
                    SMAppService.openSystemSettingsLoginItems()
                    return
                }

                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            errorMessage = L10n.launchAtLoginError(error.localizedDescription)
        }

        refreshStatus()

        if shouldEnable, service.status == .requiresApproval {
            errorMessage = L10n.launchAtLoginRequiresApproval
            SMAppService.openSystemSettingsLoginItems()
        }
    }
}
