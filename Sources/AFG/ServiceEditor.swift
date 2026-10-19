import SwiftUI

struct ServiceEditor: View {
    @Environment(\.dismiss) private var dismiss

    let service: Service?
    let onSave: (String, String, String) -> Void

    @State private var name: String
    @State private var urlString: String
    @State private var symbol: String

    init(service: Service?, onSave: @escaping (String, String, String) -> Void) {
        self.service = service
        self.onSave = onSave
        _name = State(initialValue: service?.name ?? "")
        _urlString = State(initialValue: service?.urlString ?? "https://")
        _symbol = State(initialValue: service?.symbol ?? "globe")
    }

    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host != nil else {
            return false
        }
        return true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(service == nil ? L10n.t(.addWebApp) : L10n.t(.editWebApp))
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                TextField(L10n.t(.name), text: $name)
                TextField(L10n.t(.url), text: $urlString)
                TextField(L10n.t(.sfSymbolOptional), text: $symbol)
            }
            .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button(L10n.t(.cancel)) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.t(.save)) {
                    onSave(name.trimmingCharacters(in: .whitespaces), urlString, symbol)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
