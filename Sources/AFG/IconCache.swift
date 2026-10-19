import AppKit
import Foundation

enum IconCache {
    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support")
        return base
            .appendingPathComponent("AFG", isDirectory: true)
            .appendingPathComponent("icons", isDirectory: true)
    }

    static func url(for id: String) -> URL {
        directory.appendingPathComponent("\(id).png")
    }

    static func image(for id: String) -> NSImage? {
        NSImage(contentsOf: url(for: id))
    }

    @discardableResult
    static func store(_ data: Data, for id: String) -> URL? {
        let folder = directory
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let destination = url(for: id)
        do {
            try data.write(to: destination, options: .atomic)
            return destination
        } catch {
            return nil
        }
    }
}
