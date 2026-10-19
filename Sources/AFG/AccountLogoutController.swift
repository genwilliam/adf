import AppKit
import WebKit

final class AccountLogoutController: NSObject, WKNavigationDelegate {
    static let shared = AccountLogoutController()

    private var webView: WKWebView?
    private var window: NSWindow?
    private var completion: (() -> Void)?

    func signOut(accountIndex: Int, completion: @escaping () -> Void) {
        self.completion = completion

        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 1, height: 1))
        webView.navigationDelegate = self
        self.webView = webView

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
                              styleMask: [.borderless],
                              backing: .buffered,
                              defer: false)
        window.contentView = webView
        self.window = window

        var components = URLComponents(string: "https://accounts.google.com/Logout")
        components?.queryItems = [
            URLQueryItem(name: "hl", value: L10n.language.googleCode),
            URLQueryItem(name: "authuser", value: String(accountIndex))
        ]

        guard let url = components?.url else {
            finish()
            return
        }
        webView.load(URLRequest(url: url))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.finish()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finish()
    }

    private func finish() {
        completion?()
        completion = nil
        webView?.navigationDelegate = nil
        webView = nil
        window = nil
    }
}
