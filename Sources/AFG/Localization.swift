import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh-Hans"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .english: "English"
        case .chinese: "简体中文"
        }
    }

    var googleCode: String {
        switch self {
        case .english: "en"
        case .chinese: "zh-CN"
        }
    }
}

enum L10nKey: String {
    case appSubtitle
    case searchServices
    case pinned
    case allServices
    case searchResults
    case add
    case settings
    case downloads
    case downloadWindowTitle
    case addWebApp
    case addToLaunchpad
    case addedToLaunchpad
    case addToLaunchpadFailed
    case editWebApp
    case name
    case url
    case sfSymbolOptional
    case cancel
    case save
    case pin
    case unpin
    case alwaysOnTop
    case alwaysOnTopOff
    case edit
    case delete
    case noDownloads
    case showInFinder
    case general
    case accounts
    case notifications
    case scripts
    case downloadsCategory
    case privacy
    case about
    case browsing
    case userAgent
    case pageZoom
    case loginNote
    case startupAndClose
    case launchAtLogin
    case quitOnLastClose
    case restoreWindows
    case showMenuBarIcon
    case appearance
    case appearanceSystem
    case appearanceLight
    case appearanceDark
    case language
    case loginErrorTitle
    case ok
    case accountsTitle
    case accountName
    case signOut
    case signOutTitle
    case signOutMessage
    case addAccount
    case defaultAccount
    case accountsNote
    case serviceAccounts
    case defaultAccountFormat
    case systemNotifications
    case authorized
    case notAuthorized
    case requestPermission
    case notificationsNote
    case allowedServices
    case officialScripts
    case officialGenericAds
    case officialYouTubeAds
    case userScripts
    case noScripts
    case officialScriptsNote
    case userScriptsNote
    case addScript
    case importScripts
    case exportScripts
    case importFailed
    case newScript
    case downloadsNote
    case choose
    case websiteData
    case clearWebsiteData
    case clearedWebsiteData
    case privacyNote
    case clearTitle
    case clearMessage
    case clear
    case version
    case aboutText
    case back
    case forward
    case reload
    case home
    case print
    case share
    case downloadsToolbar
    case openInBrowser
    case showAFG
    case downloadsMenu
    case settingsMenu
    case quitAFG
}

enum L10n {
    static var language: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: Prefs.languageKey) ?? "") ?? .english
    }

    static func t(_ key: L10nKey) -> String {
        let pair = table[key] ?? (key.rawValue, key.rawValue)
        return language == .english ? pair.en : pair.zh
    }

    static func t(_ key: L10nKey, _ arguments: CVarArg...) -> String {
        String(format: t(key), arguments: arguments)
    }

    static func defaultAccountName(_ index: Int) -> String {
        language == .english ? "Account \(index)" : "账号 \(index)"
    }

    private static let table: [L10nKey: (en: String, zh: String)] = [
        .appSubtitle: ("Your Google services, in one place", "你的 Google 服务，一扇窗"),
        .searchServices: ("Search services", "搜索服务"),
        .pinned: ("Pinned", "已置顶"),
        .allServices: ("All services", "全部服务"),
        .searchResults: ("Results", "搜索结果"),
        .add: ("Add", "添加"),
        .settings: ("Settings", "设置"),
        .downloads: ("Downloads", "下载"),
        .downloadWindowTitle: ("Downloads", "下载"),
        .addWebApp: ("Add Web App", "添加 Web App"),
        .addToLaunchpad: ("Add to Launchpad", "添加到启动台"),
        .addedToLaunchpad: ("Added to Launchpad", "已添加到启动台"),
        .addToLaunchpadFailed: ("Could not add to Launchpad: %@", "添加到启动台失败：%@"),
        .editWebApp: ("Edit Web App", "编辑 Web App"),
        .name: ("Name", "名称"),
        .url: ("URL", "网址"),
        .sfSymbolOptional: ("SF Symbol (optional)", "SF Symbol（可选）"),
        .cancel: ("Cancel", "取消"),
        .save: ("Save", "保存"),
        .pin: ("Pin", "置顶"),
        .unpin: ("Unpin", "取消置顶"),
        .alwaysOnTop: ("Always on Top", "窗口置顶"),
        .alwaysOnTopOff: ("Cancel Always on Top", "取消窗口置顶"),
        .edit: ("Edit…", "编辑…"),
        .delete: ("Delete", "删除"),
        .noDownloads: ("No downloads yet", "暂无下载"),
        .showInFinder: ("Show", "显示"),
        .general: ("General", "通用"),
        .accounts: ("Accounts", "账号"),
        .notifications: ("Notifications", "通知"),
        .scripts: ("Scripts", "脚本"),
        .downloadsCategory: ("Downloads", "下载"),
        .privacy: ("Privacy", "隐私"),
        .about: ("About", "关于"),
        .browsing: ("Browsing", "浏览"),
        .userAgent: ("User-Agent", "User-Agent"),
        .pageZoom: ("Page zoom", "页面缩放"),
        .loginNote: ("Signing in to Google works best with Safari (default). Changes apply to new windows.",
                     "登录 Google 建议使用 Safari（默认）。设置在下次打开服务窗口时生效。"),
        .startupAndClose: ("Startup & Close", "启动与关闭"),
        .launchAtLogin: ("Launch at login", "登录时启动"),
        .quitOnLastClose: ("Quit when the last window closes", "关闭最后一个窗口时退出"),
        .restoreWindows: ("Restore service windows on launch", "启动时恢复上次的服务窗口"),
        .showMenuBarIcon: ("Show menu bar icon", "显示菜单栏图标"),
        .appearance: ("Appearance", "外观"),
        .appearanceSystem: ("System", "跟随系统"),
        .appearanceLight: ("Light", "浅色"),
        .appearanceDark: ("Dark", "深色"),
        .language: ("Language", "语言"),
        .loginErrorTitle: ("Cannot enable launch at login", "无法设置登录时启动"),
        .ok: ("OK", "好"),
        .accountsTitle: ("Accounts", "账号"),
        .accountName: ("Account name", "账号名称"),
        .signOut: ("Sign out", "退出登录"),
        .signOutTitle: ("Sign out of this account?", "退出这个账号？"),
        .signOutMessage: ("The account is signed out from every service, then removed from AFG.",
                          "该账号会在所有服务中退出，然后从 AFG 中移除。"),
        .addAccount: ("Add account", "添加账号"),
        .defaultAccount: ("Default account", "默认账号"),
        .accountsNote: ("Account order must match the order in Google's account switcher (first = 0).",
                        "账号顺序要与 Google 多账号登录顺序一致（第一个为 0）。"),
        .serviceAccounts: ("Accounts per service", "服务账号"),
        .defaultAccountFormat: ("Default (%@)", "默认（%@）"),
        .systemNotifications: ("System notifications", "系统通知"),
        .authorized: ("Authorized", "已授权"),
        .notAuthorized: ("Not authorized", "未授权"),
        .requestPermission: ("Request permission", "请求权限"),
        .notificationsNote: ("Notifications are triggered when the unread count in a page title increases (like Gmail's \"(3)\"). WKWebView does not support Web Push, so services without an unread count never notify.",
                             "通知通过页面标题的未读数变化触发（如 Gmail 标题里的「(3)」）。WKWebView 不支持 Web Push，没有未读数的服务不会通知。"),
        .allowedServices: ("Services allowed to notify", "允许通知的服务"),
        .officialScripts: ("Official scripts", "官方脚本"),
        .officialGenericAds: ("Ad blocking (generic)", "通用广告隐藏"),
        .officialYouTubeAds: ("YouTube ad blocking", "YouTube 去广告"),
        .userScripts: ("User scripts", "用户脚本"),
        .noScripts: ("No scripts yet. Scripts are injected into every page.", "还没有脚本。脚本会在每个页面加载时注入。"),
        .officialScriptsNote: ("Official scripts are maintained by AFG and enabled by default.", "官方脚本由 AFG 维护，默认开启；关闭后不再注入。"),
        .userScriptsNote: ("Scripts are injected at page load; changes apply to new windows.", "脚本在页面加载时注入，修改后下次打开服务窗口生效。"),
        .addScript: ("Add", "添加"),
        .importScripts: ("Import…", "导入…"),
        .exportScripts: ("Export…", "导出…"),
        .importFailed: ("Import failed", "导入失败"),
        .newScript: ("New script", "新脚本"),
        .downloadsNote: ("Web downloads are saved to this folder; duplicate names get a number.", "网页下载会保存到这个目录，重名自动加序号。"),
        .choose: ("Choose…", "选择…"),
        .websiteData: ("Website data", "网站数据"),
        .clearWebsiteData: ("Clear website data…", "清除网站数据…"),
        .clearedWebsiteData: ("Website data cleared", "已清除网站数据"),
        .privacyNote: ("Deletes cookies, caches and local storage for every service; you need to sign in again.", "会删除所有服务的 Cookie、缓存与本地存储，之后需要重新登录。"),
        .clearTitle: ("Clear website data?", "清除网站数据？"),
        .clearMessage: ("Every service will need to sign in again.", "所有服务都需要重新登录。"),
        .clear: ("Clear", "清除"),
        .version: ("Version", "版本"),
        .aboutText: ("Google services as native windows, without Chrome.", "把 Google 常用服务做成独立的原生窗口，不依赖 Chrome。"),
        .back: ("Back", "后退"),
        .forward: ("Forward", "前进"),
        .reload: ("Reload", "重新载入"),
        .home: ("Home", "主页"),
        .print: ("Print", "打印"),
        .share: ("Share", "分享"),
        .downloadsToolbar: ("Downloads", "下载"),
        .openInBrowser: ("Open in Browser", "在浏览器中打开"),
        .showAFG: ("Show AFG", "显示 AFG"),
        .downloadsMenu: ("Downloads…", "下载…"),
        .settingsMenu: ("Settings…", "设置…"),
        .quitAFG: ("Quit AFG", "退出 AFG")
    ]
}
