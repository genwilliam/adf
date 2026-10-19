import AppKit
import SwiftUI

struct LauncherView: View {
    @ObservedObject private var state = AppState.shared
    @AppStorage(Prefs.languageKey) private var language = AppLanguage.english.rawValue

    @State private var query = ""
    @State private var showingAdd = false
    @State private var editingService: Service?
    @State private var launchpadMessage: String?

    private var filteredServices: [Service] {
        guard !query.isEmpty else { return state.services }
        return state.services.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var pinnedServices: [Service] {
        query.isEmpty ? state.pinnedServices : []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            searchField

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if !pinnedServices.isEmpty {
                        section(L10n.t(.pinned), services: pinnedServices)
                    }
                    section(query.isEmpty ? L10n.t(.allServices) : L10n.t(.searchResults), services: filteredServices)
                }
                .padding(.bottom, 20)
            }
        }
        .padding(20)
        .frame(minWidth: 680, minHeight: 560)
        .background(Color(nsColor: .windowBackgroundColor))
        .id(language)
        .background(WindowAccessor { window in
            window.isReleasedWhenClosed = false
            AppWindows.launcher = window
        })
        .sheet(isPresented: $showingAdd) {
            ServiceEditor(service: nil) { name, url, symbol in
                state.addCustom(name: name, urlString: url, symbol: symbol)
            }
        }
        .sheet(item: $editingService) { service in
            ServiceEditor(service: service) { name, url, symbol in
                var updated = service
                updated.name = name
                updated.urlString = url
                updated.symbol = symbol
                state.updateCustom(updated)
            }
        }
        .alert(launchpadMessage ?? "", isPresented: Binding(
            get: { launchpadMessage != nil },
            set: { if !$0 { launchpadMessage = nil } }
        )) {
            Button(L10n.t(.ok), role: .cancel) {
                launchpadMessage = nil
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("AFG")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(L10n.t(.appSubtitle))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showingAdd = true
            } label: {
                Label(L10n.t(.add), systemImage: "plus")
            }
            .help(L10n.t(.addWebApp))

            Button {
                DownloadsWindowController.shared.show()
            } label: {
                Label(L10n.t(.downloads), systemImage: "arrow.down.circle")
            }

            SettingsLink {
                Label(L10n.t(.settings), systemImage: "gearshape")
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(L10n.t(.searchServices), text: $query)
                .textFieldStyle(.plain)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func section(_ title: String, services: [Service]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 12)], spacing: 12) {
                ForEach(services) { service in
                    Button {
                        WebWindowManager.shared.open(service, accountIndex: state.accountIndex(for: service))
                    } label: {
                        ServiceTile(service: service)
                    }
                    .buttonStyle(.plain)
                    .onDrag {
                        if let url = DockLauncher.prepare(for: service) {
                            return NSItemProvider(contentsOf: url) ?? NSItemProvider()
                        }
                        return NSItemProvider()
                    }
                    .contextMenu {
                        Button(state.isPinned(service) ? L10n.t(.unpin) : L10n.t(.pin)) {
                            state.togglePin(service)
                        }
                        Button(L10n.t(.addToLaunchpad)) {
                            do {
                                _ = try LaunchpadInstaller.install(service)
                                launchpadMessage = L10n.t(.addedToLaunchpad)
                            } catch {
                                launchpadMessage = L10n.t(.addToLaunchpadFailed, error.localizedDescription)
                            }
                        }
                        if service.isCustom {
                            Button(L10n.t(.edit)) {
                                editingService = service
                            }
                            Divider()
                            Button(L10n.t(.delete), role: .destructive) {
                                state.removeCustom(service)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct ServiceTile: View {
    let service: Service

    @ObservedObject private var unread = UnreadStore.shared
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                icon

                if unread.count(for: service) > 0 {
                    Text("\(unread.count(for: service))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.red))
                        .offset(x: 6, y: -6)
                }
            }

            Text(service.name)
                .font(.caption)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(hovering ? Color(nsColor: .controlBackgroundColor) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }

    @ViewBuilder
    private var icon: some View {
        let color = Color(hex: service.colorHex)

        if let iconURL = AppState.shared.iconURL(for: service),
           let icon = NSImage(contentsOf: iconURL) {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .frame(width: 34, height: 34)
                .frame(width: 54, height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(hovering ? 0.18 : 0.08),
                        radius: hovering ? 8 : 3,
                        y: 2)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(colors: [color, color.opacity(0.72)],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                Image(systemName: service.symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 54, height: 54)
            .shadow(color: color.opacity(hovering ? 0.45 : 0.15),
                    radius: hovering ? 10 : 4,
                    y: 3)
        }
    }
}

private struct WindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onWindow(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
