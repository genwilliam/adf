import AppKit
import SwiftUI
import WebKit

enum SettingsCategory: String, CaseIterable, Identifiable {
    case general
    case accounts
    case notifications
    case scripts
    case downloads
    case privacy
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: L10n.t(.general)
        case .accounts: L10n.t(.accounts)
        case .notifications: L10n.t(.notifications)
        case .scripts: L10n.t(.scripts)
        case .downloads: L10n.t(.downloadsCategory)
        case .privacy: L10n.t(.privacy)
        case .about: L10n.t(.about)
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .accounts: "person.crop.circle"
        case .notifications: "bell"
        case .scripts: "chevron.left.forwardslash.chevron.right"
        case .downloads: "arrow.down.circle"
        case .privacy: "hand.raised"
        case .about: "info.circle"
        }
    }
}

struct SettingsView: View {
    @AppStorage(Prefs.languageKey) private var language = AppLanguage.english.rawValue
    @State private var selection: SettingsCategory? = .general

    var body: some View {
        HStack(spacing: 0) {
            List(SettingsCategory.allCases, selection: $selection) { category in
                Label(category.title, systemImage: category.symbol)
                    .tag(category)
            }
            .listStyle(.sidebar)
            .frame(width: 190)

            Divider()

            detail
                .id(language)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 820, height: 560)
    }

    @ViewBuilder
    private var detail: some View {
        switch selection ?? .general {
        case .general:
            GeneralSettingsPage()
        case .accounts:
            AccountsSettingsPage()
        case .notifications:
            NotificationsSettingsPage()
        case .scripts:
            ScriptsSettingsPage()
        case .downloads:
            DownloadsSettingsPage()
        case .privacy:
            PrivacySettingsPage()
        case .about:
            AboutSettingsPage()
        }
    }
}

private struct GeneralSettingsPage: View {
    @AppStorage(Prefs.userAgentKey) private var userAgent = Prefs.uaSafari
    @AppStorage(Prefs.pageZoomKey) private var pageZoom = 1.0
    @AppStorage(Prefs.appearanceKey) private var appearance = AppearanceMode.system.rawValue
    @AppStorage(Prefs.languageKey) private var language = AppLanguage.english.rawValue
    @AppStorage(Prefs.statusBarEnabledKey) private var statusBarEnabled = true
    @AppStorage(Prefs.closeLastWindowQuitsKey) private var closeLastWindowQuits = true
    @AppStorage(Prefs.restoreWindowsKey) private var restoreWindows = true

    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Section(L10n.t(.browsing)) {
                Picker("User-Agent", selection: $userAgent) {
                    Text("Safari").tag(Prefs.uaSafari)
                    Text("Chrome").tag(Prefs.uaChrome)
                }

                Picker(L10n.t(.pageZoom), selection: $pageZoom) {
                    Text("80%").tag(0.8)
                    Text("90%").tag(0.9)
                    Text("100%").tag(1.0)
                    Text("110%").tag(1.1)
                    Text("125%").tag(1.25)
                }

                Text(L10n.t(.loginNote))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section(L10n.t(.startupAndClose)) {
                Toggle(L10n.t(.launchAtLogin), isOn: $launchAtLogin)
                Toggle(L10n.t(.quitOnLastClose), isOn: $closeLastWindowQuits)
                Toggle(L10n.t(.restoreWindows), isOn: $restoreWindows)
                Toggle(L10n.t(.showMenuBarIcon), isOn: $statusBarEnabled)
            }

            Section(L10n.t(.appearance)) {
                Picker(L10n.t(.appearance), selection: $appearance) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }

                Picker(L10n.t(.language), selection: $language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.title).tag(language.rawValue)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .alert(L10n.t(.loginErrorTitle), isPresented: Binding(
            get: { loginError != nil },
            set: { if !$0 { loginError = nil } }
        )) {
            Button(L10n.t(.ok), role: .cancel) {
                loginError = nil
            }
        } message: {
            Text(loginError ?? "")
        }
        .onChange(of: appearance) { _, _ in
            Appearance.apply()
        }
        .onChange(of: statusBarEnabled) { _, newValue in
            StatusBarController.shared.setEnabled(newValue)
        }
        .onChange(of: launchAtLogin) { _, newValue in
            if let message = LoginItem.setEnabled(newValue) {
                loginError = message
                launchAtLogin = LoginItem.isEnabled
            }
        }
    }
}

private struct AccountsSettingsPage: View {
    var body: some View {
        Form {
            AccountSettingsSection()
        }
        .formStyle(.grouped)
    }
}

private struct NotificationsSettingsPage: View {
    @ObservedObject private var manager = NotificationManager.shared
    @ObservedObject private var state = AppState.shared

    var body: some View {
        Form {
            Section(L10n.t(.systemNotifications)) {
                HStack {
                    Text(manager.authorized ? L10n.t(.authorized) : L10n.t(.notAuthorized))
                    Spacer()
                    if !manager.authorized {
                        Button(L10n.t(.requestPermission)) {
                            manager.requestAuthorization()
                        }
                    }
                }

                Text(L10n.t(.notificationsNote))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section(L10n.t(.allowedServices)) {
                ForEach(state.services) { service in
                    Toggle(service.name, isOn: Binding(
                        get: { manager.isEnabled(for: service) },
                        set: { manager.setEnabled($0, for: service) }
                    ))
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { manager.refreshAuthorization() }
        .onAppear {
            manager.refreshAuthorization()
        }
    }
}

private struct ScriptsSettingsPage: View {
    @State private var enabled: [String: Bool] = Dictionary(
        uniqueKeysWithValues: OfficialScripts.all.map { ($0.id, OfficialScripts.isEnabled($0)) }
    )

    var body: some View {
        Form {
            Section(L10n.t(.officialScripts)) {
                ForEach(OfficialScripts.all) { script in
                    Toggle(displayName(for: script), isOn: Binding(
                        get: { enabled[script.id] ?? true },
                        set: {
                            enabled[script.id] = $0
                            OfficialScripts.setEnabled($0, for: script)
                        }
                    ))
                }

                Text(L10n.t(.officialScriptsNote))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ScriptSettingsSection()
        }
        .formStyle(.grouped)
    }

    private func displayName(for script: OfficialScript) -> String {
        switch script.id {
        case "generic-ads": L10n.t(.officialGenericAds)
        case "youtube-ads": L10n.t(.officialYouTubeAds)
        default: script.name
        }
    }
}

private struct DownloadsSettingsPage: View {
    @AppStorage(Prefs.downloadDirectoryKey) private var downloadDirectory = ""

    var body: some View {
        Form {
            Section(L10n.t(.downloadsCategory)) {
                HStack {
                    Text(downloadPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button(L10n.t(.choose)) {
                        chooseDirectory()
                    }
                }

                Text(L10n.t(.downloadsNote))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var downloadPath: String {
        downloadDirectory.isEmpty
            ? "~/Downloads"
            : (downloadDirectory as NSString).abbreviatingWithTildeInPath
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "OK"

        if panel.runModal() == .OK, let url = panel.url {
            downloadDirectory = url.path
        }
    }
}

private struct PrivacySettingsPage: View {
    @State private var confirmingClear = false
    @State private var cleared = false

    var body: some View {
        Form {
            Section(L10n.t(.websiteData)) {
                Button(L10n.t(.clearWebsiteData)) {
                    confirmingClear = true
                }

                if cleared {
                    Text(L10n.t(.clearedWebsiteData))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text(L10n.t(.privacyNote))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .alert(L10n.t(.clearTitle), isPresented: $confirmingClear) {
            Button(L10n.t(.clear), role: .destructive) {
                clearWebsiteData()
            }
            Button(L10n.t(.cancel), role: .cancel) {}
        } message: {
            Text(L10n.t(.clearMessage))
        }
    }

    private func clearWebsiteData() {
        WKWebsiteDataStore.default().removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: .distantPast
        ) {
            DispatchQueue.main.async {
                cleared = true
            }
        }
    }
}

private struct AboutSettingsPage: View {
    var body: some View {
        Form {
            Section("AFG") {
                HStack {
                    Text(L10n.t(.version))
                    Spacer()
                    Text(version)
                        .foregroundStyle(.secondary)
                }

                Text(L10n.t(.aboutText))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
}
