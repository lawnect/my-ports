import AppKit
import SwiftUI
import ShowMeThePortsCore

struct PortPopoverView: View {
    @ObservedObject var viewModel: PortListViewModel
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            filterBar
            Divider()
            content
            errorFooter
            Divider()
            footer
        }
        .frame(width: 420, height: 488)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Label("My Ports", systemImage: "network")
                .font(.headline)

            Spacer()

            Button {
                Task {
                    await viewModel.refresh()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.isLoading)
            .help("Refresh")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var filterBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("Filter")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 42, alignment: .leading)

                Spacer(minLength: 0)

                Picker("Filter", selection: $viewModel.filterMode) {
                    ForEach(PortFilterMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.small)
                .fixedSize(horizontal: true, vertical: false)
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 42, alignment: .leading)

                TextField("Port", text: $viewModel.portSearchText)
                    .font(.system(.body, design: .monospaced))
                    .textFieldStyle(.roundedBorder)

                if !viewModel.portSearchText.isEmpty {
                    Button {
                        viewModel.portSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .help("Clear")
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
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

                Text(viewModel.isLoading ? "Looking for listening ports..." : viewModel.emptyStateMessage)
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
        if let errorMessage = viewModel.errorMessage {
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
            Text(viewModel.footerStatus)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Quit", role: .destructive, action: onQuit)
                .keyboardShortcut("q")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct PortRowView: View {
    let entry: PortEntry
    let isKilling: Bool
    let onKill: () -> Void

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
                    Text(entry.processName)
                        .font(.subheadline)
                        .lineLimit(1)

                    Text("·")
                        .foregroundStyle(.tertiary)

                    Text(classification.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .help(classification.reason)
                }
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text("PID \(entry.pid)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)

                Text(entry.endpoint)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Button(role: .destructive, action: onKill) {
                if isKilling {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "xmark.circle.fill")
                }
            }
            .buttonStyle(.borderless)
            .disabled(isKilling)
            .help("Kill \(entry.processName) (\(entry.pid))")
        }
        .padding(.vertical, 4)
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
        .help(classification.reason)
    }

    private var brandImage: NSImage? {
        guard let iconName = classification.iconName else {
            return nil
        }

        #if SWIFT_PACKAGE
        let resourceBundle = Bundle.module
        #else
        let resourceBundle = Bundle.main
        #endif

        let iconURL = resourceBundle.url(
            forResource: iconName,
            withExtension: "svg",
            subdirectory: "ServiceIcons"
        ) ?? resourceBundle.url(forResource: iconName, withExtension: "svg")

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
