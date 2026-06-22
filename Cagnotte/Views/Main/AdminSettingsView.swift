import SwiftUI

struct AdminSettingsView: View {
    @StateObject private var vm: AdminSettingsViewModel
    @State private var showCopied = false

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: AdminSettingsViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if vm.isLoading {
                    ProgressView().tint(.greenPrimary).padding(40)
                } else {
                    // Invite code
                    if let code = vm.colocation?.inviteCode {
                        inviteCodeCard(code)
                    }

                    // Settings form
                    settingsForm

                    // Danger zone
                    dangerSection
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .padding(.bottom, 40)
        }
        .background(Color.screenBackground.ignoresSafeArea())
        .navigationTitle("Paramètres Admin")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { vm.load() }
        .toast(message: Binding(
            get: { vm.errorMessage },
            set: { vm.errorMessage = $0 }
        ), type: .error)
        .toast(message: Binding(
            get: { vm.successMessage },
            set: { vm.successMessage = $0 }
        ), type: .success)
    }

    private func inviteCodeCard(_ code: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Code d'invitation")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.subtitleText)
            HStack {
                Text(code)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.darkText)
                    .tracking(4)
                Spacer()
                Button {
                    UIPasteboard.general.string = code
                    withAnimation { showCopied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showCopied = false }
                    }
                } label: {
                    Label(showCopied ? "Copié !" : "Copier", systemImage: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(showCopied ? .greenPrimary : .appBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background((showCopied ? Color.greenPrimary : Color.appBlue).opacity(0.12))
                        .cornerRadius(10)
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var settingsForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Paramètres")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.darkText)

            VStack(alignment: .leading, spacing: 6) {
                Text("Nom de la colocation")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.subtitleText)
                AppTextField(placeholder: "Nom", text: $vm.colocationName)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Seuil d'alerte écart de dépenses (€)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.subtitleText)
                AppTextField(placeholder: "Ex: 50", text: $vm.spendingGapThreshold)
                    .keyboardType(.decimalPad)
            }

            PrimaryButton(title: "Sauvegarder", isLoading: vm.isSaving) {
                vm.saveSettings()
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.subtitleText)

            Button {
                vm.generateRotation()
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Générer la rotation")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.appBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appBlue.opacity(0.1))
                .cornerRadius(16)
            }
        }
    }
}
