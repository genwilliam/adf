import AppKit

final class IconHostDelegate: NSObject, NSApplicationDelegate {
    private var monitor: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let ownerPID = (Bundle.main.object(forInfoDictionaryKey: "AFGOwnerPID") as? NSNumber)?.int32Value

        monitor = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            let owner = ownerPID.flatMap { NSRunningApplication(processIdentifier: $0) }
            if owner == nil {
                NSApp.terminate(nil)
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openService()
        return true
    }

    private func openService() {
        guard let id = Bundle.main.object(forInfoDictionaryKey: "AFGServiceID") as? String,
              let url = URL(string: "afg://service/\(id)") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

let application = NSApplication.shared
let delegate = IconHostDelegate()
application.delegate = delegate
application.setActivationPolicy(.regular)
application.run()
