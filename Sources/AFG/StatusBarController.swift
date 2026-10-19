import AppKit

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    static let shared = StatusBarController()

    private var statusItem: NSStatusItem?

    func setEnabled(_ enabled: Bool) {
        if enabled {
            guard statusItem == nil else { return }
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            item.button?.image = NSImage(systemSymbolName: "square.grid.2x2.fill",
                                         accessibilityDescription: "AFG")
            let menu = NSMenu()
            menu.delegate = self
            item.menu = menu
            statusItem = item
        } else if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let show = NSMenuItem(title: L10n.t(.showAFG), action: #selector(showWindows), keyEquivalent: "")
        show.target = self
        menu.addItem(show)

        menu.addItem(.separator())

        let services = AppState.shared.pinnedServices.isEmpty
            ? Array(AppState.shared.services.prefix(8))
            : AppState.shared.pinnedServices

        for service in services {
            let item = NSMenuItem(title: service.name, action: #selector(openService(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = service.id
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let downloads = NSMenuItem(title: L10n.t(.downloadsMenu), action: #selector(openDownloads), keyEquivalent: "")
        downloads.target = self
        menu.addItem(downloads)

        let settings = NSMenuItem(title: L10n.t(.settingsMenu), action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let quit = NSMenuItem(title: L10n.t(.quitAFG), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
    }

    @objc private func showWindows() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if let launcher = AppWindows.launcher {
            launcher.makeKeyAndOrderFront(nil)
            return
        }
        for window in NSApp.windows where window.isVisible {
            window.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func openService(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let service = AppState.shared.services.first(where: { $0.id == id }) else {
            return
        }
        WebWindowManager.shared.open(service, accountIndex: AppState.shared.accountIndex(for: service))
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if !NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    @objc private func openDownloads() {
        NSApp.activate(ignoringOtherApps: true)
        DownloadsWindowController.shared.show()
    }
}
