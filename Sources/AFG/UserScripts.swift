import SwiftUI

struct UserScript: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var source: String
    var enabled: Bool
}

final class UserScriptStore: ObservableObject {
    static let shared = UserScriptStore()

    @Published private(set) var scripts: [UserScript]

    private let fileURL: URL?

    private init() {
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("AFG", isDirectory: true)
        if let directory {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        fileURL = directory?.appendingPathComponent("user-scripts.json")

        if let fileURL, let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([UserScript].self, from: data) {
            scripts = decoded
        } else {
            scripts = []
        }
    }

    var enabledScripts: [UserScript] {
        scripts.filter { $0.enabled }
    }

    func upsert(_ script: UserScript) {
        if let index = scripts.firstIndex(where: { $0.id == script.id }) {
            scripts[index] = script
        } else {
            scripts.append(script)
        }
        save()
    }

    func delete(_ script: UserScript) {
        scripts.removeAll { $0.id == script.id }
        save()
    }

    func setEnabled(_ script: UserScript, _ enabled: Bool) {
        guard let index = scripts.firstIndex(where: { $0.id == script.id }) else { return }
        scripts[index].enabled = enabled
        save()
    }

    func importScripts(from url: URL) throws {
        let data = try Data(contentsOf: url)

        if let decoded = try? JSONDecoder().decode([UserScript].self, from: data) {
            for var script in decoded {
                script.id = UUID()
                scripts.append(script)
            }
        } else {
            let source = String(decoding: data, as: UTF8.self)
            guard !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw CocoaError(.fileReadCorruptFile)
            }
            scripts.append(UserScript(id: UUID(),
                                      name: url.deletingPathExtension().lastPathComponent,
                                      source: source,
                                      enabled: true))
        }

        save()
    }

    func exportAll(to url: URL) throws {
        let data = try JSONEncoder().encode(scripts)
        try data.write(to: url, options: .atomic)
    }

    private func save() {
        guard let fileURL else { return }
        do {
            try JSONEncoder().encode(scripts).write(to: fileURL, options: .atomic)
        } catch {
            NSLog("AFG user scripts: %@", error.localizedDescription)
        }
    }
}

struct UserScriptEditor: View {
    @Environment(\.dismiss) private var dismiss

    let script: UserScript
    let onSave: (UserScript) -> Void

    @State private var name: String
    @State private var source: String

    init(script: UserScript, onSave: @escaping (UserScript) -> Void) {
        self.script = script
        self.onSave = onSave
        _name = State(initialValue: script.name)
        _source = State(initialValue: script.source)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(L10n.t(.name), text: $name)
                .textFieldStyle(.roundedBorder)

            TextEditor(text: $source)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 300)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor))
                )

            HStack {
                Spacer()
                Button(L10n.t(.cancel)) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.t(.save)) {
                    var updated = script
                    updated.name = name.trimmingCharacters(in: .whitespaces)
                    updated.source = source
                    onSave(updated)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding(20)
        .frame(width: 680, height: 480)
    }
}
