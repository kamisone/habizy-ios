import SwiftUI

struct CompleteProfileView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var selectedColorHex = Color.presetHexColors[0]
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var repo: AuthRepository {
        AuthRepository(api: APIService.configure(tokenManager: tokenManager), tokenManager: tokenManager)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(LinearGradient.greenGradient)
                            .frame(width: 72, height: 72)
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 32))
                    }
                    Text("Complète ton profil")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.darkText)
                    Text("Pour accéder à ta colocation, remplis tes informations.")
                        .font(.system(size: 14))
                        .foregroundColor(.subtitleText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                // Form
                VStack(spacing: 16) {
                    AppTextField(placeholder: "Nom complet", text: $name)
                    AppTextField(placeholder: "Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    AppTextField(placeholder: "Mot de passe (min. 6 caractères)", text: $password, isSecure: true)

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
                                            .stroke(Color.white, lineWidth: selectedColorHex == hex ? 3 : 0)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: hex), lineWidth: selectedColorHex == hex ? 2 : 0)
                                            .padding(-2)
                                    )
                                    .onTapGesture { selectedColorHex = hex }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let err = errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.coralRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    PrimaryButton(
                        title: "Enregistrer",
                        isLoading: isLoading,
                        disabled: name.isEmpty || email.isEmpty || password.count < 6
                    ) {
                        Task { await submit() }
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(22)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

                // Logout button
                Button {
                    authViewModel.deleteAccountAndLogout()
                } label: {
                    Text("Se déconnecter")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.subtitleText)
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.screenBackground.ignoresSafeArea())
    }

    private func submit() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            _ = try await repo.completeProfile(
                name: name,
                email: email,
                password: password,
                colorHex: selectedColorHex,
                phone: nil
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
