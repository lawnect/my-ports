import AppKit
import SwiftUI
import ShowMeThePortsCore

struct PortPopoverView: View {
    @ObservedObject var viewModel: PortListViewModel
    @StateObject private var launchAtLogin = LaunchAtLoginController()
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            Divider()
            content
            errorFooter
            Divider()
            footer
        }
        .frame(width: 420, height: 488)
        .onAppear {
            launchAtLogin.refreshStatus()
        }
    }

    private var header: some View {
        ZStack {
            if viewModel.showsFilterPicker {
                Picker(L10n.filter, selection: $viewModel.filterMode) {
                    ForEach(viewModel.availableFilterModes) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.small)
                .fixedSize(horizontal: true, vertical: false)
            }

            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(nsImage: MenuBarIcon.image)
                        .resizable()
                        .frame(width: 18, height: 18)
                        .accessibilityHidden(true)

                    Text(L10n.appName)
                        .font(.headline)
                }

                Spacer(minLength: 8)

                Menu {
                    Toggle(
                        L10n.launchAtLogin,
                        isOn: Binding(
                            get: { launchAtLogin.isEnabled },
                            set: { isEnabled in
                                launchAtLogin.setEnabled(isEnabled)
                            }
                        )
                    )

                    Divider()

                    Button(L10n.quit, role: .destructive, action: onQuit)
                        .keyboardShortcut("q")
                } label: {
                    Label(L10n.settings, systemImage: "gearshape")
                        .labelStyle(.iconOnly)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help(L10n.settings)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var searchBar: some View {
        PortSearchField(
            text: $viewModel.portSearchText,
            placeholder: L10n.searchPlaceholder
        )
        .frame(height: 26)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.ports.isEmpty {
            VStack(spacing: 10) {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                }

                Text(viewModel.isLoading ? L10n.lookingForPorts : viewModel.emptyStateMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(viewModel.ports) { entry in
                PortRowView(
                    entry: entry,
                    isKilling: viewModel.killingPIDs.contains(entry.pid),
                    onKill: {
                        Task {
                            await viewModel.kill(entry)
                        }
                    }
                )
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }

    @ViewBuilder
    private var errorFooter: some View {
        if let errorMessage = viewModel.errorMessage ?? launchAtLogin.errorMessage {
            Divider()

            Label(errorMessage, systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.red)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button {
                Task {
                    await viewModel.refresh()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.isLoading)
            .help(L10n.refresh)

            Text(viewModel.footerStatus)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct PortSearchField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField()
        searchField.placeholderString = placeholder
        searchField.sendsSearchStringImmediately = true
        searchField.delegate = context.coordinator
        return searchField
    }

    func updateNSView(_ searchField: NSSearchField, context: Context) {
        context.coordinator.text = $text
        searchField.placeholderString = placeholder

        if searchField.stringValue != text {
            searchField.stringValue = text
        }
    }

    final class Coordinator: NSObject, NSSearchFieldDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let searchField = notification.object as? NSSearchField else {
                return
            }

            text.wrappedValue = searchField.stringValue
        }
    }
}

private struct PortRowView: View {
    let entry: PortEntry
    let isKilling: Bool
    let onKill: () -> Void
    @State private var isShowingKillConfirmation = false

    private var classification: PortClassification {
        entry.classification
    }

    var body: some View {
        HStack(spacing: 12) {
            ServiceIconView(classification: classification)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(String(entry.port))
                        .font(.system(.title3, design: .monospaced).weight(.semibold))

                    Text(entry.protocolName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 5) {
                    Text(L10n.localizedProcessName(entry.processName))
                        .font(.subheadline)
                        .lineLimit(1)

                    Text("·")
                        .foregroundStyle(.tertiary)

                    Text(L10n.classificationName(classification.displayName))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .help(L10n.classificationReason(classification.reason))
                }
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text(L10n.pid(entry.pid))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)

                Text(entry.endpoint)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Button(role: .destructive) {
                isShowingKillConfirmation = true
            } label: {
                if isKilling {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "xmark.circle.fill")
                }
            }
            .buttonStyle(.borderless)
            .disabled(isKilling)
            .help(L10n.killHelp(processName: entry.processName, pid: entry.pid))
        }
        .padding(.vertical, 4)
        .alert(
            L10n.terminateProcessTitle,
            isPresented: $isShowingKillConfirmation
        ) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.terminate, role: .destructive, action: onKill)
        } message: {
            Text(
                L10n.terminateProcessMessage(
                    processName: entry.processName,
                    pid: entry.pid,
                    port: entry.port
                )
            )
        }
    }
}

private struct ServiceIconView: View {
    let classification: PortClassification

    var body: some View {
        Group {
            if let image = brandImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: fallbackSymbolName)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 22, height: 22)
        .accessibilityHidden(true)
        .help(L10n.classificationReason(classification.reason))
    }

    private var brandImage: NSImage? {
        guard let iconName = classification.iconName else {
            return nil
        }

        let iconURL = AppResources.bundle.url(
            forResource: iconName,
            withExtension: "svg",
            subdirectory: "ServiceIcons"
        ) ?? AppResources.bundle.url(forResource: iconName, withExtension: "svg")

        guard let iconURL else {
            return nil
        }

        return NSImage(contentsOf: iconURL)
    }

    private var fallbackSymbolName: String {
        switch classification.category {
        case .web: "globe"
        case .database: "cylinder"
        case .cache: "memorychip"
        case .messaging: "arrow.left.arrow.right"
        case .container: "shippingbox"
        case .mobile: "iphone"
        case .development: "hammer"
        case .system: "gearshape"
        case .other: "questionmark.circle"
        }
    }
}
