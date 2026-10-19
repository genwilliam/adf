import Foundation

enum LaunchpadInstaller {
    static func install(_ service: Service) throws -> URL {
        guard let source = DockLauncher.prepare(for: service) else {
            throw CocoaError(.fileWriteUnknown)
        }

        let destination = URL(fileURLWithPath: "/Applications", isDirectory: true)
            .appendingPathComponent(source.lastPathComponent)
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: source, to: destination)
        return destination
    }
}
