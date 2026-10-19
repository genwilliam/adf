import AppKit

enum Prefs {
    static let userAgentKey = "afg.userAgent"
    static let appearanceKey = "afg.appearance"
    static let statusBarEnabledKey = "afg.statusBarEnabled"
    static let closeLastWindowQuitsKey = "afg.closeLastWindowQuits"
    static let restoreWindowsKey = "afg.restoreWindows"
    static let downloadDirectoryKey = "afg.downloadDirectory"
    static let pageZoomKey = "afg.pageZoom"
    static let openServiceIDsKey = "afg.openServiceIDs"
    static let languageKey = "afg.language"

    static let uaChrome = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36"
    static let uaSafari = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15"

    static var userAgent: String {
        UserDefaults.standard.string(forKey: userAgentKey) ?? uaSafari
    }

    static var pageZoom: Double {
        let value = UserDefaults.standard.double(forKey: pageZoomKey)
        return value == 0 ? 1 : value
    }

    static var downloadDirectoryURL: URL {
        if let path = UserDefaults.standard.string(forKey: downloadDirectoryKey), !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
    }

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            userAgentKey: uaSafari,
            appearanceKey: AppearanceMode.system.rawValue,
            statusBarEnabledKey: true,
            closeLastWindowQuitsKey: true,
            restoreWindowsKey: true,
            pageZoomKey: 1.0,
            languageKey: AppLanguage.english.rawValue
        ])
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: L10n.t(.appearanceSystem)
        case .light: L10n.t(.appearanceLight)
        case .dark: L10n.t(.appearanceDark)
        }
    }

    var appearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}

enum Appearance {
    static func apply() {
        let raw = UserDefaults.standard.string(forKey: Prefs.appearanceKey) ?? AppearanceMode.system.rawValue
        NSApp.appearance = (AppearanceMode(rawValue: raw) ?? .system).appearance
    }
}
