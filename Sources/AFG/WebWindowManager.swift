import AppKit

@MainActor
final class WebWindowManager {
    static let shared = WebWindowManager()

    private var controllers: [String: WebWindowController] = [:]

    var openServiceIDs: [String] {
        Array(controllers.keys)
    }

    func open(_ service: Service, accountIndex: Int = 0) {
        if let existing = controllers[service.id] {
            if existing.accountIndex == accountIndex {
                existing.window?.makeKeyAndOrderFront(nil)
                return
            }
            existing.close()
        }
        let controller = WebWindowController(service: service, accountIndex: accountIndex)
        controllers[service.id] = controller
        NSApp.activate(ignoringOtherApps: true)
        ServiceDockIcon.show(for: service)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    func remove(_ id: String) {
        controllers[id] = nil
        if let service = AppState.shared.services.first(where: { $0.id == id }) {
            ServiceDockIcon.hide(for: service)
        }
    }
}
