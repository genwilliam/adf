import AppKit
import Foundation

enum ServiceIconLoader {
    static func load(from url: URL, completion: @escaping (Data?) -> Void) {
        guard let host = url.host else {
            completion(nil)
            return
        }

        let candidates: [URL?] = [
            URL(string: "https://\(host)/apple-touch-icon.png"),
            URL(string: "https://\(host)/favicon.ico"),
            URL(string: "https://www.google.com/s2/favicons?sz=128&domain=\(host)")
        ]

        tryNext(candidates.compactMap { $0 }, index: 0, completion: completion)
    }

    private static func tryNext(_ urls: [URL], index: Int, completion: @escaping (Data?) -> Void) {
        guard index < urls.count else {
            completion(nil)
            return
        }

        var request = URLRequest(url: urls[index])
        request.timeoutInterval = 6

        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data, let image = NSImage(data: data), image.size.width >= 16,
               let tiff = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiff),
               let png = bitmap.representation(using: .png, properties: [:]) {
                DispatchQueue.main.async {
                    completion(png)
                }
            } else {
                tryNext(urls, index: index + 1, completion: completion)
            }
        }.resume()
    }
}
