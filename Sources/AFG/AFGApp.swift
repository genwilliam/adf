import SwiftUI

@main
struct AFGApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("AFG", id: "launcher") {
            LauncherView()
        }
        .defaultSize(width: 760, height: 620)
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView()
        }
    }
}

enum AppWindows {
    static weak var launcher: NSWindow?
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var suppressReopenUntil = Date.distantPast
    private var pendingReopen: DispatchWorkItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Prefs.registerDefaults()
        Appearance.apply()
        ServiceDockIcon.prepare()
        StatusBarController.shared.setEnabled(UserDefaults.standard.bool(forKey: Prefs.statusBarEnabledKey))
        NotificationManager.shared.requestAuthorizationIfNeeded()
        restoreWindowsIfNeeded()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        UserDefaults.standard.bool(forKey: Prefs.closeLastWindowQuitsKey)
    }

    func applicationWillTerminate(_ notification: Notification) {
        ServiceDockIcon.hideAll()
        let restores = UserDefaults.standard.bool(forKey: Prefs.restoreWindowsKey)
        let ids = restores
            ? MainActor.assumeIsolated { WebWindowManager.shared.openServiceIDs }
            : []
        UserDefaults.standard.set(ids, forKey: Prefs.openServiceIDsKey)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        pendingReopen?.cancel()

        let work = DispatchWorkItem { [weak self] in
            guard let self, Date() >= self.suppressReopenUntil else { return }
            NSApp.setActivationPolicy(.regular)
            AppWindows.launcher?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        pendingReopen = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)

        return true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        pendingReopen?.cancel()
        suppressReopenUntil = Date().addingTimeInterval(1)
        Task { @MainActor in
            for url in urls where url.scheme == "afg" {
                guard url.host == "service",
                      let id = url.pathComponents.dropFirst().first,
                      let service = AppState.shared.services.first(where: { $0.id == id }) else {
                    continue
                }
                WebWindowManager.shared.open(service, accountIndex: AppState.shared.accountIndex(for: service))
            }
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func restoreWindowsIfNeeded() {
        guard UserDefaults.standard.bool(forKey: Prefs.restoreWindowsKey) else { return }
        let ids = UserDefaults.standard.stringArray(forKey: Prefs.openServiceIDsKey) ?? []
        guard !ids.isEmpty else { return }

        Task { @MainActor in
            for id in ids {
                if let service = AppState.shared.services.first(where: { $0.id == id }) {
                    WebWindowManager.shared.open(service, accountIndex: AppState.shared.accountIndex(for: service))
                }
            }
        }
    }
}
