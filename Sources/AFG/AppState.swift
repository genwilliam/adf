import Foundation

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published private(set) var customServices: [Service]
    @Published private(set) var pinnedIDs: Set<String>
    @Published private(set) var accounts: [String]
    @Published private(set) var defaultAccountIndex: Int
    @Published private(set) var serviceAccounts: [String: Int]

    private static let customKey = "afg.customServices"
    private static let pinnedKey = "afg.pinnedServices"
    private static let accountsKey = "afg.accounts"
    private static let defaultAccountKey = "afg.defaultAccount"
    private static let serviceAccountsKey = "afg.serviceAccounts"
    private static let palette = ["#4285F4", "#EA4335", "#0F9D58", "#F4B400", "#8E7CFF", "#00AC47", "#FF5722", "#00C4FF"]

    private let defaults = UserDefaults.standard

    private init() {
        let data = UserDefaults.standard.data(forKey: Self.customKey)
        customServices = data.flatMap { try? JSONDecoder().decode([Service].self, from: $0) } ?? []
        pinnedIDs = Set(UserDefaults.standard.stringArray(forKey: Self.pinnedKey) ?? [])

        let storedAccounts = UserDefaults.standard.stringArray(forKey: Self.accountsKey) ?? []
        accounts = storedAccounts.isEmpty ? [L10n.defaultAccountName(1)] : storedAccounts
        defaultAccountIndex = UserDefaults.standard.integer(forKey: Self.defaultAccountKey)
        let storedServiceAccounts = UserDefaults.standard.dictionary(forKey: Self.serviceAccountsKey) ?? [:]
        serviceAccounts = storedServiceAccounts.compactMapValues { $0 as? Int }

        for service in customServices where service.iconFile == nil {
            loadIcon(for: service)
        }
    }

    var services: [Service] {
        ServiceCatalog.builtin + customServices
    }

    var pinnedServices: [Service] {
        services.filter { pinnedIDs.contains($0.id) }
    }

    func isPinned(_ service: Service) -> Bool {
        pinnedIDs.contains(service.id)
    }

    func togglePin(_ service: Service) {
        if pinnedIDs.contains(service.id) {
            pinnedIDs.remove(service.id)
        } else {
            pinnedIDs.insert(service.id)
        }
        defaults.set(Array(pinnedIDs), forKey: Self.pinnedKey)
    }

    func addCustom(name: String, urlString: String, symbol: String) {
        let service = Service(
            id: UUID().uuidString,
            name: name,
            urlString: urlString,
            symbol: symbol.isEmpty ? "globe" : symbol,
            colorHex: Self.palette[Int(name.hashValue.magnitude % UInt(Self.palette.count))],
            isCustom: true
        )
        customServices.append(service)
        saveCustom()
        loadIcon(for: service)
    }

    func updateCustom(_ service: Service) {
        guard let index = customServices.firstIndex(where: { $0.id == service.id }) else { return }
        let urlChanged = customServices[index].urlString != service.urlString
        customServices[index] = service
        if urlChanged {
            customServices[index].iconFile = nil
            loadIcon(for: service)
        }
        saveCustom()
    }

    func removeCustom(_ service: Service) {
        customServices.removeAll { $0.id == service.id }
        pinnedIDs.remove(service.id)
        saveCustom()
        defaults.set(Array(pinnedIDs), forKey: Self.pinnedKey)
    }

    func accountIndex(for service: Service) -> Int {
        serviceAccounts[service.id] ?? defaultAccountIndex
    }

    func accountName(at index: Int) -> String {
        accounts.indices.contains(index) ? accounts[index] : L10n.defaultAccountName(1)
    }

    func addAccount() {
        accounts.append(L10n.defaultAccountName(accounts.count + 1))
        saveAccounts()
    }

    func renameAccount(at index: Int, to name: String) {
        guard accounts.indices.contains(index) else { return }
        accounts[index] = name
        saveAccounts()
    }

    func removeAccount(at index: Int) {
        guard accounts.count > 1, accounts.indices.contains(index) else { return }
        accounts.remove(at: index)

        if defaultAccountIndex == index {
            defaultAccountIndex = 0
        } else if defaultAccountIndex > index {
            defaultAccountIndex -= 1
        }

        serviceAccounts = serviceAccounts.compactMapValues { value in
            if value == index { return nil }
            return value > index ? value - 1 : value
        }

        saveAccounts()
        defaults.set(defaultAccountIndex, forKey: Self.defaultAccountKey)
        defaults.set(serviceAccounts, forKey: Self.serviceAccountsKey)
    }

    func setDefaultAccount(_ index: Int) {
        guard accounts.indices.contains(index) else { return }
        defaultAccountIndex = index
        defaults.set(index, forKey: Self.defaultAccountKey)
    }

    func setAccount(_ index: Int?, for service: Service) {
        if let index, accounts.indices.contains(index) {
            serviceAccounts[service.id] = index
        } else {
            serviceAccounts[service.id] = nil
        }
        defaults.set(serviceAccounts, forKey: Self.serviceAccountsKey)
    }

    func iconURL(for service: Service) -> URL? {
        guard service.iconFile != nil else { return nil }
        return IconCache.url(for: service.id)
    }

    private func loadIcon(for service: Service) {
        ServiceIconLoader.load(from: service.url) { [weak self] data in
            guard let data else { return }
            Task { @MainActor in
                self?.applyIcon(data, for: service.id)
            }
        }
    }

    private func applyIcon(_ data: Data, for id: String) {
        guard IconCache.store(data, for: id) != nil,
              let index = customServices.firstIndex(where: { $0.id == id }) else { return }

        customServices[index].iconFile = IconCache.url(for: id).lastPathComponent
        saveCustom()
    }

    private func saveAccounts() {
        defaults.set(accounts, forKey: Self.accountsKey)
    }

    private func saveCustom() {
        defaults.set(try? JSONEncoder().encode(customServices), forKey: Self.customKey)
    }
}
