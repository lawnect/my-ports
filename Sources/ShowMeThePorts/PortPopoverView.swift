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

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(String(entry.port))
                        .font(.system(.title3, design: .monospaced).weight(.semibold))

                    Text(entry.protocolName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(entry.processName)
                    .font(.subheadline)
                    .lineLimit(1)
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
