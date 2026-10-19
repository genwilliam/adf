import AppKit
import Foundation

enum DockLauncher {
    static func prepare(for service: Service) -> URL? {
        let folder = applicationFolder
        let bundle = folder.appendingPathComponent(sanitizedName(service.name) + ".app")
        let contents = bundle.appendingPathComponent("Contents")
        let macOS = contents.appendingPathComponent("MacOS")
        let executable = macOS.appendingPathComponent("Launcher")
        let plist = contents.appendingPathComponent("Info.plist")
        let resources = contents.appendingPathComponent("Resources")

        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: macOS, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: resources, withIntermediateDirectories: true)
        } catch {
            return nil
        }

        let script = "#!/bin/sh\nexec open \"afg://service/\(service.id)\"\n"
        do {
            try script.write(to: executable, atomically: true, encoding: .utf8)
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)
        } catch {
            return nil
        }

        let info: [String: Any] = [
            "CFBundleIdentifier": "dev.genwilliam.afg.launch.\(service.id)",
            "CFBundleName": service.name,
            "CFBundleDisplayName": service.name,
            "CFBundleExecutable": "Launcher",
            "CFBundleIconFile": "AppIcon",
            "CFBundlePackageType": "APPL",
            "CFBundleShortVersionString": "1.0",
            "CFBundleVersion": "1",
            "LSMinimumSystemVersion": "15.0",
            "NSHighResolutionCapable": true
        ]
        guard let data = try? PropertyListSerialization.data(fromPropertyList: info,
                                                             format: .xml,
                                                             options: 0),
              (try? data.write(to: plist, options: .atomic)) != nil else {
            return nil
        }

        try? ServiceIconRenderer.icnsData(for: service)
            .write(to: resources.appendingPathComponent("AppIcon.icns"), options: .atomic)
        try? fileManager.removeItem(at: bundle.appendingPathComponent("Icon\r"))

        return bundle
    }

    private static var applicationFolder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support")
        return base
            .appendingPathComponent("AFG", isDirectory: true)
            .appendingPathComponent("Dock Apps", isDirectory: true)
    }

    private static func sanitizedName(_ name: String) -> String {
        name.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
    }
}
