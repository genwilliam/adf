import AppKit
import Foundation

final class UnreadStore: ObservableObject {
    static let shared = UnreadStore()

    @Published private(set) var counts: [String: Int] = [:]

    func count(for service: Service) -> Int {
        counts[service.id] ?? 0
    }

    @discardableResult
    func update(service: Service, title: String?) -> (previous: Int, current: Int) {
        guard let title else {
            return (counts[service.id] ?? 0, counts[service.id] ?? 0)
        }

        let previous = counts[service.id] ?? 0
        let current = Self.unreadCount(in: title)

        if current > 0 {
            counts[service.id] = current
        } else {
            counts[service.id] = nil
        }
        updateDockBadge()

        return (previous, current)
    }

    private func updateDockBadge() {
        let total = counts.values.reduce(0, +)
        NSApp.dockTile.badgeLabel = total > 0 ? String(total) : nil
    }

    private static func unreadCount(in title: String) -> Int {
        guard let range = title.range(of: #"\((\d+)\)"#, options: .regularExpression) else {
            return 0
        }
        let digits = title[range].dropFirst().dropLast()
        return Int(digits) ?? 0
    }
}
