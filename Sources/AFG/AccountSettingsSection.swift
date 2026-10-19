import SwiftUI

struct AccountSettingsSection: View {
    @ObservedObject private var state = AppState.shared

    @State private var pendingLogoutIndex: Int?

    var body: some View {
        Section(L10n.t(.accountsTitle)) {
            ForEach(Array(state.accounts.enumerated()), id: \.offset) { index, _ in
                HStack {
                    TextField(L10n.t(.accountName), text: Binding(
                        get: { state.accountName(at: index) },
                        set: { state.renameAccount(at: index, to: $0) }
                    ))

                    Menu {
                        Button(L10n.t(.signOut), role: .destructive) {
                            pendingLogoutIndex = index
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
            }

            Button(L10n.t(.addAccount)) {
                state.addAccount()
            }

            Picker(L10n.t(.defaultAccount), selection: Binding(
                get: { state.defaultAccountIndex },
                set: { state.setDefaultAccount($0) }
            )) {
                ForEach(state.accounts.indices, id: \.self) { index in
                    Text(state.accountName(at: index)).tag(index)
                }
            }

            Text(L10n.t(.accountsNote))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }

        Section(L10n.t(.serviceAccounts)) {
            ForEach(state.services) { service in
                Picker(service.name, selection: Binding(
                    get: { state.serviceAccounts[service.id] ?? -1 },
                    set: { state.setAccount($0 >= 0 ? $0 : nil, for: service) }
                )) {
                    Text(L10n.t(.defaultAccountFormat, state.accountName(at: state.defaultAccountIndex)))
                        .tag(-1)

                    ForEach(state.accounts.indices.filter { $0 != state.defaultAccountIndex }, id: \.self) { index in
                        Text(state.accountName(at: index)).tag(index)
                    }
                }
            }
        }
        .alert(L10n.t(.signOutTitle), isPresented: Binding(
            get: { pendingLogoutIndex != nil },
            set: { if !$0 { pendingLogoutIndex = nil } }
        )) {
            Button(L10n.t(.signOut), role: .destructive) {
                guard let index = pendingLogoutIndex else { return }
                pendingLogoutIndex = nil
                AccountLogoutController.shared.signOut(accountIndex: index) {
                    state.removeAccount(at: index)
                }
            }
            Button(L10n.t(.cancel), role: .cancel) {
                pendingLogoutIndex = nil
            }
        } message: {
            Text(L10n.t(.signOutMessage))
        }
    }
}
