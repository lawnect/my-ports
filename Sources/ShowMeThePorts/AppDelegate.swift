import AppKit
import SwiftUI
import ShowMeThePortsCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let viewModel = PortListViewModel()
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        configurePopover()

        Task {
            await viewModel.refresh()
        }
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else {
            return
        }

        let image = NSImage(systemSymbolName: "network", accessibilityDescription: "My Ports")
        image?.isTemplate = true

        button.image = image
        button.toolTip = "My Ports"
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
