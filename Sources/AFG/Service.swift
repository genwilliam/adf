import SwiftUI

struct Service: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var urlString: String
    var symbol: String
    var colorHex: String
    var isCustom: Bool = false
    var iconFile: String? = nil

    var url: URL {
        URL(string: urlString) ?? URL(string: "about:blank")!
    }

    var usesChromeUserAgent: Bool {
        url.host?.contains("docs.google.com") == true
    }

    var supportsAccounts: Bool {
        guard let host = url.host else { return false }
        return host.contains("google.") || host.contains("youtube.com")
    }

    func url(forAccountIndex index: Int, language: AppLanguage = L10n.language) -> URL {
        guard supportsAccounts,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        if index > 0 {
            components.path = components.path.replacingOccurrences(of: "/u/0/", with: "/u/\(index)/")
        }

        var items = components.queryItems ?? []

        if index > 0 {
            if let existing = items.firstIndex(where: { $0.name == "authuser" }) {
                items[existing].value = String(index)
            } else {
                items.append(URLQueryItem(name: "authuser", value: String(index)))
            }
        }

        if let existing = items.firstIndex(where: { $0.name == "hl" }) {
            items[existing].value = language.googleCode
        } else {
            items.append(URLQueryItem(name: "hl", value: language.googleCode))
        }

        components.queryItems = items
        return components.url ?? url
    }
}

enum ServiceCatalog {
    static let builtin: [Service] = [
        Service(id: "youtube", name: "YouTube", urlString: "https://www.youtube.com/", symbol: "play.rectangle.fill", colorHex: "#FF0033"),
        Service(id: "gmail", name: "Gmail", urlString: "https://mail.google.com/mail/u/0/#inbox", symbol: "envelope.fill", colorHex: "#EA4335"),
        Service(id: "drive", name: "Google Drive", urlString: "https://drive.google.com/drive/home", symbol: "externaldrive.fill", colorHex: "#0F9D58"),
        Service(id: "docs", name: "Google Docs", urlString: "https://docs.google.com/document/u/0/", symbol: "doc.text.fill", colorHex: "#4285F4"),
        Service(id: "sheets", name: "Google Sheets", urlString: "https://docs.google.com/spreadsheets/u/0/", symbol: "tablecells.fill", colorHex: "#0F9D58"),
        Service(id: "slides", name: "Google Slides", urlString: "https://docs.google.com/presentation/u/0/", symbol: "rectangle.on.rectangle.fill", colorHex: "#F4B400"),
        Service(id: "calendar", name: "Google Calendar", urlString: "https://calendar.google.com/calendar/u/0/r", symbol: "calendar", colorHex: "#4285F4"),
        Service(id: "maps", name: "Google Maps", urlString: "https://www.google.com/maps?authuser=0", symbol: "map.fill", colorHex: "#34A853"),
        Service(id: "photos", name: "Google Photos", urlString: "https://photos.google.com/", symbol: "photo.fill", colorHex: "#4285F4"),
        Service(id: "meet", name: "Google Meet", urlString: "https://meet.google.com/?hs=197&authuser=0", symbol: "video.fill", colorHex: "#00832D"),
        Service(id: "keep", name: "Google Keep", urlString: "https://keep.google.com/", symbol: "note.text", colorHex: "#F4B400"),
        Service(id: "translate", name: "Google Translate", urlString: "https://translate.google.com/", symbol: "character.bubble.fill", colorHex: "#4285F4"),
        Service(id: "news", name: "Google News", urlString: "https://news.google.com/home?hl=en-US&gl=US&ceid=US:en", symbol: "newspaper.fill", colorHex: "#4285F4"),
        Service(id: "gemini", name: "Gemini", urlString: "https://gemini.google.com/app", symbol: "sparkles", colorHex: "#8E7CFF"),
        Service(id: "earth", name: "Google Earth", urlString: "https://earth.google.com/", symbol: "globe.americas.fill", colorHex: "#4285F4"),
        Service(id: "search", name: "Google Search", urlString: "https://www.google.com/", symbol: "magnifyingglass", colorHex: "#4285F4"),
        Service(id: "forms", name: "Google Forms", urlString: "https://docs.google.com/forms/u/0/", symbol: "list.bullet.rectangle.fill", colorHex: "#7248B9"),
        Service(id: "books", name: "Google Books", urlString: "https://books.google.com/?authuser=0", symbol: "book.fill", colorHex: "#4285F4"),
        Service(id: "travel", name: "Google Travel", urlString: "https://www.google.com/travel/?authuser=0", symbol: "airplane", colorHex: "#4285F4"),
        Service(id: "contacts", name: "Google Contacts", urlString: "https://contacts.google.com/", symbol: "person.crop.circle.fill", colorHex: "#4285F4"),
        Service(id: "blogger", name: "Blogger", urlString: "https://www.blogger.com/dashboard/reading", symbol: "square.and.pencil", colorHex: "#FF5722"),
        Service(id: "play", name: "Google Play", urlString: "https://play.google.com/store/apps", symbol: "square.grid.2x2.fill", colorHex: "#00C4FF"),
        Service(id: "chat", name: "Google Chat", urlString: "https://mail.google.com/chat/u/0/#chat/home", symbol: "bubble.left.and.bubble.right.fill", colorHex: "#00AC47"),
        Service(id: "shopping", name: "Google Shopping", urlString: "https://shopping.google.com/", symbol: "bag.fill", colorHex: "#4285F4"),
        Service(id: "finance", name: "Google Finance", urlString: "https://www.google.com/finance/?authuser=0", symbol: "chart.line.uptrend.xyaxis", colorHex: "#0F9D58"),
        Service(id: "classroom", name: "Google Classroom", urlString: "https://classroom.google.com/", symbol: "graduationcap.fill", colorHex: "#0F9D58"),
        Service(id: "arts", name: "Arts & Culture", urlString: "https://artsandculture.google.com/", symbol: "paintpalette.fill", colorHex: "#EA4335"),
        Service(id: "voice", name: "Google Voice", urlString: "https://voice.google.com/u/0/about", symbol: "phone.fill", colorHex: "#4285F4"),
        Service(id: "fi", name: "Google Fi", urlString: "https://fi.google.com/about/", symbol: "wifi", colorHex: "#4285F4"),
        Service(id: "ads", name: "Google Ads", urlString: "https://ads.google.com/home/", symbol: "megaphone.fill", colorHex: "#4285F4"),
        Service(id: "remotedesktop", name: "Chrome Remote Desktop", urlString: "https://remotedesktop.google.com/access/", symbol: "display", colorHex: "#4285F4")
    ]
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0x4285F4
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
