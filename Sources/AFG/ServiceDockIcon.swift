import AppKit

enum ServiceDockIcon {
    private static let layoutVersion = 3
    private static let layoutKey = "afg.serviceIconsLayoutVersion"

    private static var visible: Set<String> = []

    static func prepare() {
        guard UserDefaults.standard.integer(forKey: layoutKey) != layoutVersion else { return }

        for application in NSWorkspace.shared.runningApplications
        where application.bundleIdentifier?.hasPrefix("dev.genwilliam.afg.icon.") == true {
            application.terminate()
        }

        try? FileManager.default.removeItem(at: rootFolder)
        UserDefaults.standard.set(layoutVersion, forKey: layoutKey)
    }

    static func show(for service: Service) {
        launch(service)
    }

    static func hide(for service: Service) {
        visible.remove(service.id)
        terminate(bundleID: bundleID(for: service.id))
    }

    static func hideAll() {
        for id in visible {
            terminate(bundleID: bundleID(for: id))
        }
        visible.removeAll()
    }

    private static func launch(_ service: Service) {
        let identifier = bundleID(for: service.id)
        guard NSRunningApplication.runningApplications(withBundleIdentifier: identifier).isEmpty else {
            visible.insert(service.id)
            return
        }

        guard let bundle = makeBundle(for: service) else { return }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        NSWorkspace.shared.openApplication(at: bundle, configuration: configuration) { _, _ in }
        visible.insert(service.id)
    }

    private static func terminate(bundleID: String) {
        for application in NSRunningApplication.runningApplications(withBundleIdentifier: bundleID) {
            application.terminate()
        }
    }

    private static func bundleID(for serviceID: String) -> String {
        "dev.genwilliam.afg.icon.v\(layoutVersion).\(serviceID)"
    }

    private static func makeBundle(for service: Service) -> URL? {
        guard let host = Bundle.main.url(forAuxiliaryExecutable: "AFGIconHost") else {
            return nil
        }

        let bundle = folder.appendingPathComponent(sanitizedName(service.name) + ".app")
        let staging = rootFolder.appendingPathComponent(".staging-\(UUID().uuidString).app")
        defer { try? FileManager.default.removeItem(at: staging) }

        let contents = staging.appendingPathComponent("Contents")
        let macOS = contents.appendingPathComponent("MacOS")
        let executable = macOS.appendingPathComponent("AFGIconHost")
        let plist = contents.appendingPathComponent("Info.plist")
        let resources = contents.appendingPathComponent("Resources")

        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: macOS, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: resources, withIntermediateDirectories: true)
            try fileManager.copyItem(at: host, to: executable)
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)
        } catch {
            return nil
        }

        guard let icns = try? ServiceIconRenderer.icnsData(for: service) else { return nil }
        try? icns.write(to: resources.appendingPathComponent("AppIcon.icns"), options: .atomic)

        let info: [String: Any] = [
            "CFBundleIdentifier": bundleID(for: service.id),
            "CFBundleName": service.name,
            "CFBundleDisplayName": service.name,
            "CFBundleExecutable": "AFGIconHost",
            "CFBundleIconFile": "AppIcon",
            "CFBundlePackageType": "APPL",
            "CFBundleShortVersionString": "1.0",
            "CFBundleVersion": "1",
            "AFGServiceID": service.id,
            "AFGOwnerPID": ProcessInfo.processInfo.processIdentifier,
            "LSMinimumSystemVersion": "15.0",
            "NSHighResolutionCapable": true
        ]

        guard let data = try? PropertyListSerialization.data(fromPropertyList: info,
                                                             format: .xml,
                                                             options: 0),
              (try? data.write(to: plist, options: .atomic)) != nil else {
            return nil
        }

        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        try? fileManager.removeItem(at: bundle)
        do {
            try fileManager.moveItem(at: staging, to: bundle)
        } catch {
            return nil
        }

        return bundle
    }

    private static var rootFolder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support")
        return base
            .appendingPathComponent("AFG", isDirectory: true)
            .appendingPathComponent("Service Icons", isDirectory: true)
    }

    private static var folder: URL {
        rootFolder.appendingPathComponent("v\(layoutVersion)", isDirectory: true)
    }

    private static func sanitizedName(_ name: String) -> String {
        name.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
    }
}
