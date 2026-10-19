import AppKit
import SwiftUI

final class DownloadItem: ObservableObject, Identifiable {
    enum State: Equatable {
        case downloading
        case finished
        case failed
    }

    let id = UUID()
    let fileName: String
    let destination: URL

    @Published var progress: Double = 0
    @Published var state: State = .downloading

    init(fileName: String, destination: URL) {
        self.fileName = fileName
        self.destination = destination
    }
}

final class DownloadsStore: ObservableObject {
    static let shared = DownloadsStore()

    @Published private(set) var items: [DownloadItem] = []

    func add(_ item: DownloadItem) {
        items.insert(item, at: 0)
    }
}

final class DownloadsWindowController: NSWindowController {
    static let shared = DownloadsWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 420),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.t(.downloadWindowTitle)
        window.center()
        window.contentView = NSHostingView(rootView: DownloadsView())
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}

struct DownloadsView: View {
    @ObservedObject private var store = DownloadsStore.shared

    var body: some View {
        Group {
            if store.items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text(L10n.t(.noDownloads))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(store.items) { item in
                    DownloadRow(item: item)
                }
            }
        }
        .frame(minWidth: 460, minHeight: 360)
    }
}

private struct DownloadRow: View {
    @ObservedObject var item: DownloadItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.fileName)
                    .lineLimit(1)

                if item.state == .downloading {
                    ProgressView(value: item.progress)
                        .progressViewStyle(.linear)
                } else {
                    Text(item.destination.deletingLastPathComponent().path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if item.state == .finished {
                Button(L10n.t(.showInFinder)) {
                    NSWorkspace.shared.activateFileViewerSelecting([item.destination])
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var icon: String {
        switch item.state {
        case .downloading: "arrow.down.circle"
        case .finished: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch item.state {
        case .downloading: .accentColor
        case .finished: .green
        case .failed: .red
        }
    }
}
