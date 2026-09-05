import AppKit
import SwiftUI
import ShowMeThePortsCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let viewModel = PortListViewModel()
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var autoRefreshTask: Task<Void, Never>?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        configurePopover()
        observeMenuTracking()
        startAutoRefresh()
    }

    func applicationWillTerminate(_ notification: Notification) {
        autoRefreshTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else {
            return
        }

        button.image = MenuBarIcon.image
        button.toolTip = L10n.appName
        button.setAccessibilityLabel(L10n.appName)
        button.target = self
        button.action = #selector(togglePopover(_:))
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 420, height: 460)
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: PortPopoverView(
                viewModel: viewModel,
                onQuit: { NSApp.terminate(nil) }
            )
        )
    }

    private func observeMenuTracking() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(menuDidEndTracking(_:)),
            name: NSMenu.didEndTrackingNotification,
            object: nil
        )
    }

    @objc private func menuDidEndTracking(_ notification: Notification) {
        guard popover.isShown,
              let popoverWindow = popover.contentViewController?.view.window,
              !popoverWindow.frame.contains(NSEvent.mouseLocation) else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self, self.popover.isShown else {
                return
            }

            self.popover.performClose(nil)
        }
    }

    private func startAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = Task { [weak self] in
            var showsActivity = true

            while !Task.isCancelled {
                guard let self else {
                    return
                }

                await self.viewModel.refresh(showsActivity: showsActivity)
                showsActivity = false

                do {
                    try await Task.sleep(for: .seconds(3))
                } catch {
                    return
                }
            }
        }
    }

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem?.button else {
            return
        }

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()

        Task {
            await viewModel.refresh()
        }
    }
}
