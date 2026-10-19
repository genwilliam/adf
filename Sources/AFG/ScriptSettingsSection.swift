import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ScriptSettingsSection: View {
    @ObservedObject private var store = UserScriptStore.shared

    @State private var editing: UserScript?
    @State private var importError: String?

    var body: some View {
        Section(L10n.t(.userScripts)) {
            if store.scripts.isEmpty {
                Text(L10n.t(.noScripts))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.scripts) { script in
                    HStack {
                        Toggle("", isOn: Binding(
                            get: { script.enabled },
                            set: { store.setEnabled(script, $0) }
                        ))
                        .labelsHidden()

                        Text(script.name)

                        Spacer()

                        Button(L10n.t(.edit)) {
                            editing = script
                        }
                        .buttonStyle(.plain)

                        Button {
                            store.delete(script)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Button(L10n.t(.addScript)) {
                    editing = UserScript(id: UUID(), name: L10n.t(.newScript), source: "", enabled: true)
                }
                Button(L10n.t(.importScripts)) {
                    importScripts()
                }
                Button(L10n.t(.exportScripts)) {
                    exportScripts()
                }
            }

            Text(L10n.t(.userScriptsNote))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .sheet(item: $editing) { script in
            UserScriptEditor(script: script) { updated in
                store.upsert(updated)
            }
        }
        .alert(L10n.t(.importFailed), isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button(L10n.t(.ok), role: .cancel) {
                importError = nil
            }
        } message: {
            Text(importError ?? "")
        }
    }

    private func importScripts() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.javaScript, .json]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try store.importScripts(from: url)
        } catch {
            importError = error.localizedDescription
        }
    }

    private func exportScripts() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "afg-user-scripts.json"
        panel.allowedContentTypes = [.json]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try store.exportAll(to: url)
        } catch {
            importError = error.localizedDescription
        }
    }
}
