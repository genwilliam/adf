import AppKit
import Foundation
import UserNotifications

final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    @Published private(set) var authorized = false
    @Published private(set) var allowed: Set<String>

    private let center = UNUserNotificationCenter.current()

    private static let allowedKey = "afg.notificationServices"

    private override init() {
        allowed = Set(UserDefaults.standard.stringArray(forKey: Self.allowedKey) ?? [])
        super.init()
        center.delegate = self
        refreshAuthorization()
    }

    func refreshAuthorization() {
        center.getNotificationSettings { [weak self] settings in
            let granted = settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
            DispatchQueue.main.async {
                self?.authorized = granted
                Task { @MainActor in NotificationMonitor.shared.sync() }
            }
        }
    }

    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { [weak self] settings in
            if settings.authorizationStatus == .notDetermined {
                self?.requestAuthorization()
            } else {
                self?.refreshAuthorization()
            }
        }
    }

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] _, _ in
            self?.refreshAuthorization()
        }
    }

    func isEnabled(for service: Service) -> Bool {
        allowed.contains(service.id)
    }

    func setEnabled(_ enabled: Bool, for service: Service) {
        if enabled {
            allowed.insert(service.id)
        } else {
            allowed.remove(service.id)
        }
        UserDefaults.standard.set(Array(allowed), forKey: Self.allowedKey)
        Task { @MainActor in NotificationMonitor.shared.sync() }
    }

    func primeTitle(_ title: String?, for service: Service) {
        guard let title else { return }
        _ = UnreadStore.shared.update(service: service, title: title)
    }

    func handleTitle(_ title: String?, for service: Service) {
        guard let title else { return }

        let result = UnreadStore.shared.update(service: service, title: title)
        guard authorized, isEnabled(for: service), result.current > result.previous else { return }
        post(service: service, title: title, count: result.current)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if let id = response.notification.request.content.userInfo["serviceID"] as? String {
            Task { @MainActor in
                if let service = AppState.shared.services.first(where: { $0.id == id }) {
                    WebWindowManager.shared.open(service, accountIndex: AppState.shared.accountIndex(for: service))
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
        completionHandler()
    }

    private func post(service: Service, title: String, count: Int) {
        let content = UNMutableNotificationContent()
        content.title = service.name
        content.body = title
        content.userInfo = ["serviceID": service.id]
        content.badge = NSNumber(value: count)

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        center.add(request)
    }
}
