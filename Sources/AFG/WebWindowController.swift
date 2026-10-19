import AppKit
import WebKit

private extension NSToolbarItem.Identifier {
    static let afgBack = NSToolbarItem.Identifier("afg.back")
    static let afgForward = NSToolbarItem.Identifier("afg.forward")
    static let afgReload = NSToolbarItem.Identifier("afg.reload")
    static let afgHome = NSToolbarItem.Identifier("afg.home")
    static let afgPin = NSToolbarItem.Identifier("afg.pin")
    static let afgPrint = NSToolbarItem.Identifier("afg.print")
    static let afgShare = NSToolbarItem.Identifier("afg.share")
    static let afgDownloads = NSToolbarItem.Identifier("afg.downloads")
    static let afgOpenExternal = NSToolbarItem.Identifier("afg.openExternal")
}

final class WebWindowController: NSWindowController, NSWindowDelegate, NSToolbarDelegate,
    WKNavigationDelegate, WKDownloadDelegate, WKScriptMessageHandler {

    let service: Service
    let accountIndex: Int
    private let webView: WKWebView
    private let progress = NSProgressIndicator()
    private var progressObservation: NSKeyValueObservation?
    private var titleObservation: NSKeyValueObservation?
    private var loadRetries = 0
    private var downloadItems: [ObjectIdentifier: DownloadItem] = [:]
    private var downloadObservations: [ObjectIdentifier: NSKeyValueObservation] = [:]
    private var pinItem: NSToolbarItem?
    private var hasLoaded = false
    private var isFloating = false
    private let openedAt = Date()

    init(service: Service, accountIndex: Int) {
        self.service = service
        self.accountIndex = accountIndex

        let configuration = WKWebViewConfiguration()
        for script in OfficialScripts.enabledScripts {
            configuration.userContentController.addUserScript(
                WKUserScript(source: script.source,
                             injectionTime: .atDocumentStart,
                             forMainFrameOnly: false)
            )
        }
        for script in UserScriptStore.shared.enabledScripts {
            configuration.userContentController.addUserScript(
                WKUserScript(source: script.source,
                             injectionTime: .atDocumentStart,
                             forMainFrameOnly: false)
            )
        }

        configuration.processPool = WKProcessPool()
        configuration.userContentController.addUserScript(
            WKUserScript(source: ScrollDamping.script,
                         injectionTime: .atDocumentStart,
                         forMainFrameOnly: true)
        )

        webView = WKWebView(frame: .zero, configuration: configuration)
        let userAgent = (Prefs.userAgent == Prefs.uaSafari && service.usesChromeUserAgent)
            ? Prefs.uaChrome
            : Prefs.userAgent
        webView.customUserAgent = userAgent
        if Prefs.pageZoom != 1 {
            webView.pageZoom = Prefs.pageZoom
        }
        webView.allowsBackForwardNavigationGestures = true

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1120, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = service.name
        window.toolbarStyle = .unified

        super.init(window: window)

        window.delegate = self
        window.center()
        window.setFrameAutosaveName("afg.window.\(service.id)")

        webView.navigationDelegate = self
        webView.configuration.userContentController.add(self, name: "afgPrint")
        webView.configuration.userContentController.addUserScript(
            WKUserScript(source: "window.print = function () { window.webkit.messageHandlers.afgPrint.postMessage(null); };",
                         injectionTime: .atDocumentStart,
                         forMainFrameOnly: true)
        )

        let toolbar = NSToolbar(identifier: "afg.service.toolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar

        progress.style = .bar
        progress.isIndeterminate = false
        progress.minValue = 0
        progress.maxValue = 1
        progress.isHidden = true
        progress.translatesAutoresizingMaskIntoConstraints = false
        webView.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(progress)
        content.addSubview(webView)

        NSLayoutConstraint.activate([
            progress.topAnchor.constraint(equalTo: content.topAnchor),
            progress.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            progress.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            progress.heightAnchor.constraint(equalToConstant: 2),
            webView.topAnchor.constraint(equalTo: progress.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: content.bottomAnchor)
        ])

        window.contentView = content

        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            let value = webView.estimatedProgress
            DispatchQueue.main.async {
                guard let self else { return }
                self.progress.doubleValue = value
                self.progress.isHidden = value >= 1
            }
        }

        titleObservation = webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
            let title = webView.title
            DispatchQueue.main.async {
                guard let self else { return }
                self.window?.title = (title?.isEmpty == false ? title : nil) ?? self.service.name

                if Date().timeIntervalSince(self.openedAt) < 10 {
                    NotificationManager.shared.primeTitle(title, for: self.service)
                } else {
                    NotificationManager.shared.handleTitle(title, for: self.service)
                }
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)

        guard !hasLoaded else { return }
        hasLoaded = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.webView.load(URLRequest(url: self.service.url(forAccountIndex: self.accountIndex)))
        }
    }

    func windowWillClose(_ notification: Notification) {
        progressObservation?.invalidate()
        titleObservation?.invalidate()
        downloadObservations.values.forEach { $0.invalidate() }
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "afgPrint")
        WebWindowManager.shared.remove(service.id)
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.afgBack, .afgForward, .afgReload, .afgHome, .afgPin, .flexibleSpace,
         .afgPrint, .afgShare, .afgDownloads, .afgOpenExternal]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.isBordered = true
        item.target = self

        switch itemIdentifier {
        case .afgBack:
            item.label = L10n.t(.back)
            item.image = NSImage(systemSymbolName: "chevron.backward", accessibilityDescription: L10n.t(.back))
            item.action = #selector(goBack)
        case .afgForward:
            item.label = L10n.t(.forward)
            item.image = NSImage(systemSymbolName: "chevron.forward", accessibilityDescription: L10n.t(.forward))
            item.action = #selector(goForward)
        case .afgReload:
            item.label = L10n.t(.reload)
            item.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: L10n.t(.reload))
            item.action = #selector(reload)
        case .afgHome:
            item.label = L10n.t(.home)
            item.image = NSImage(systemSymbolName: "house", accessibilityDescription: L10n.t(.home))
            item.action = #selector(goHome)
        case .afgPin:
            item.label = isFloating ? L10n.t(.alwaysOnTopOff) : L10n.t(.alwaysOnTop)
            item.image = NSImage(systemSymbolName: isFloating ? "pin.fill" : "pin",
                                 accessibilityDescription: L10n.t(.alwaysOnTop))
            item.action = #selector(toggleAlwaysOnTop)
            pinItem = item
        case .afgPrint:
            item.label = L10n.t(.print)
            item.image = NSImage(systemSymbolName: "printer", accessibilityDescription: L10n.t(.print))
            item.action = #selector(printPage)
        case .afgShare:
            item.label = L10n.t(.share)
            item.image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: L10n.t(.share))
            item.action = #selector(share)
        case .afgDownloads:
            item.label = L10n.t(.downloadsToolbar)
            item.image = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: L10n.t(.downloadsToolbar))
            item.action = #selector(showDownloads)
        case .afgOpenExternal:
            item.label = L10n.t(.openInBrowser)
            item.image = NSImage(systemSymbolName: "safari", accessibilityDescription: L10n.t(.openInBrowser))
            item.action = #selector(openExternal)
        default:
            return nil
        }
        return item
    }

    @objc private func goBack() { webView.goBack() }
    @objc private func goForward() { webView.goForward() }
    @objc private func reload() { webView.reload() }
    @objc private func goHome() { webView.load(URLRequest(url: service.url(forAccountIndex: accountIndex))) }

    @objc private func toggleAlwaysOnTop() {
        isFloating.toggle()
        window?.level = isFloating ? .floating : .normal
        pinItem?.label = isFloating ? L10n.t(.alwaysOnTopOff) : L10n.t(.alwaysOnTop)
        pinItem?.image = NSImage(systemSymbolName: isFloating ? "pin.fill" : "pin",
                                 accessibilityDescription: L10n.t(.alwaysOnTop))
    }

    @objc private func openExternal() {
        NSWorkspace.shared.open(webView.url ?? service.url)
    }

    @objc private func printPage() {
        let operation = webView.printOperation(with: NSPrintInfo.shared)
        operation.showsPrintPanel = true
        operation.showsProgressPanel = true
        operation.run()
    }

    @objc private func share() {
        guard let url = webView.url else { return }
        let picker = NSSharingServicePicker(items: [url])
        picker.show(relativeTo: webView.bounds, of: webView, preferredEdge: .minY)
    }

    @objc private func showDownloads() {
        DownloadsWindowController.shared.show()
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(navigationAction.shouldPerformDownload ? .download : .allow)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(navigationResponse.canShowMIMEType ? .allow : .download)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadRetries = 0
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        guard nsError.code != NSURLErrorCancelled, loadRetries < 1 else { return }

        loadRetries += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            let current = self.webView.url?.absoluteString ?? ""
            guard current.isEmpty || current == "about:blank" else { return }
            self.webView.load(URLRequest(url: self.service.url(forAccountIndex: self.accountIndex)))
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        loadRetries = 0
        let current = webView.url?.absoluteString ?? ""
        if current.isEmpty || current == "about:blank" {
            webView.load(URLRequest(url: service.url(forAccountIndex: accountIndex)))
        } else {
            webView.reload()
        }
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    func download(_ download: WKDownload,
                  decideDestinationUsing response: URLResponse,
                  suggestedFilename: String,
                  completionHandler: @escaping (URL?) -> Void) {
        let directory = Prefs.downloadDirectoryURL
        let destination = Self.uniqueDestination(in: directory, fileName: suggestedFilename)
        let item = DownloadItem(fileName: destination.lastPathComponent, destination: destination)
        DownloadsStore.shared.add(item)

        let key = ObjectIdentifier(download)
        downloadItems[key] = item
        downloadObservations[key] = download.progress.observe(\.fractionCompleted, options: [.new]) { progress, _ in
            let value = progress.fractionCompleted
            DispatchQueue.main.async {
                item.progress = value
            }
        }

        completionHandler(destination)
    }

    func downloadDidFinish(_ download: WKDownload) {
        let key = ObjectIdentifier(download)
        downloadItems[key]?.state = .finished
        downloadItems[key] = nil
        downloadObservations[key]?.invalidate()
        downloadObservations[key] = nil
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        let key = ObjectIdentifier(download)
        downloadItems[key]?.state = .failed
        downloadItems[key] = nil
        downloadObservations[key]?.invalidate()
        downloadObservations[key] = nil
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "afgPrint" {
            printPage()
        }
    }

    private static func uniqueDestination(in directory: URL, fileName: String) -> URL {
        let base = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        var candidate = directory.appendingPathComponent(fileName)
        var index = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            let name = ext.isEmpty ? "\(base) (\(index))" : "\(base) (\(index)).\(ext)"
            candidate = directory.appendingPathComponent(name)
            index += 1
        }
        return candidate
    }
}
