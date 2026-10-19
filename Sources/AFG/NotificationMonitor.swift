import AppKit
import WebKit

@MainActor
final class NotificationMonitor {
    static let shared = NotificationMonitor()

    private var webViews: [String: WKWebView] = [:]
    private var observations: [String: NSKeyValueObservation] = [:]
    private var startedAt: [String: Date] = [:]

    func sync() {
        guard NotificationManager.shared.authorized else {
            stopAll()
            return
        }

        let allowed = NotificationManager.shared.allowed
        for id in webViews.keys where !allowed.contains(id) {
            stop(id)
        }
        for service in AppState.shared.services where allowed.contains(service.id) {
            start(service)
        }
    }

    private func start(_ service: Service) {
        guard webViews[service.id] == nil else { return }

        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()

        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 1024, height: 768),
                                configuration: configuration)
        webView.customUserAgent = (Prefs.userAgent == Prefs.uaSafari && service.usesChromeUserAgent)
            ? Prefs.uaChrome
            : Prefs.userAgent

        observations[service.id] = webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
            DispatchQueue.main.async {
                guard let self, let title = webView.title else { return }

                let started = self.startedAt[service.id] ?? .distantPast
                if Date().timeIntervalSince(started) < 30 {
                    NotificationManager.shared.primeTitle(title, for: service)
                } else {
                    NotificationManager.shared.handleTitle(title, for: service)
                }
            }
        }

        startedAt[service.id] = Date()
        webViews[service.id] = webView
        let account = AppState.shared.accountIndex(for: service)
        webView.load(URLRequest(url: service.url(forAccountIndex: account, language: L10n.language)))
    }

    private func stop(_ id: String) {
        observations[id]?.invalidate()
        observations[id] = nil
        webViews[id]?.stopLoading()
        webViews[id] = nil
        startedAt[id] = nil
    }

    private func stopAll() {
        for id in Array(webViews.keys) {
            stop(id)
        }
    }
}
