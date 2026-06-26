import SwiftUI

struct CreateUserView: View {
    @StateObject private var vm: CreateUserViewModel
    @State private var showResult = false

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: CreateUserViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Ajouter un colocataire")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.darkText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 14) {
                    AppTextField(placeholder: "Nom complet", text: $vm.name)
                    AppTextField(placeholder: "Email", text: $vm.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    AppTextField(placeholder: "Mot de passe (optionnel — généré auto)", text: $vm.password, isSecure: true)

                    // Color picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Couleur")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.subtitleText)
                        HStack(spacing: 14) {
                            ForEach(Color.presetHexColors, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: vm.selectedColorHex == hex ? 3 : 0)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: hex), lineWidth: vm.selectedColorHex == hex ? 2 : 0)
                                            .padding(-2)
                                    )
                                    .onTapGesture { vm.selectedColorHex = hex }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let err = vm.errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.coralRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    PrimaryButton(
                        title: "Créer le compte",
                        isLoading: vm.isLoading,
                        disabled: !vm.canSubmit
                    ) {
                        vm.createUser()
                    }
                }
                .padding(18)
                .background(Color.white)
                .cornerRadius(22)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.screenBackground.ignoresSafeArea())
        .navigationTitle("Nouveau colocataire")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: vm.createdUser) { result in
            if result != nil { showResult = true }
        }
        .sheet(isPresented: $showResult) {
            if let result = vm.createdUser {
                GeneratedPasswordSheet(result: result, onDismiss: {
                    showResult = false
                    vm.createdUser = nil
                })
            }
        }
    }
}

private struct GeneratedPasswordSheet: View {
    let result: CreateUserResponse
    let onDismiss: () -> Void
    @State private var copied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Avatar
                RoommateAvatar(user: result.user, size: 72, cornerRadius: 24, fontSize: 28)

                VStack(spacing: 6) {
                    Text(result.user.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.darkText)
                    Text(result.user.email)
                        .font(.system(size: 14))
                        .foregroundColor(.subtitleText)
                }

                if let pwd = result.generatedPassword {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Mot de passe généré")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.subtitleText)

                        HStack {
                            Text(pwd)
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(.darkText)
                                .tracking(3)
                            Spacer()
                            Button {
                                UIPasteboard.general.string = pwd
                                withAnimation { copied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { copied = false }
                                }
                            } label: {
                                Label(copied ? "Copié !" : "Copier", systemImage: copied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(copied ? .greenPrimary : .appBlue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background((copied ? Color.greenPrimary : Color.appBlue).opacity(0.12))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(18)
                    .background(Color.lightCardBg)
                    .cornerRadius(16)

                    Text("Transmets ce mot de passe au colocataire pour qu'il puisse se connecter.")
                        .font(.system(size: 13))
                        .foregroundColor(.subtitleText)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                Button(action: onDismiss) {
                    Text("Fermer")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.greenPrimary)
                        .cornerRadius(18)
                }
            }
            .padding(24)
            .background(Color.screenBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer", action: onDismiss)
                }
            }
        }
    }
}
