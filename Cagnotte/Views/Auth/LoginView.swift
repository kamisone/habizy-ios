import SwiftUI

struct LoginView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var inviteCode = ""
    @State private var loginError: String?
    @State private var joinError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Green gradient header
                ZStack {
                    LinearGradient.greenVertical
                        .ignoresSafeArea(edges: .top)
                    VStack(spacing: 4) {
                        Text("Cagnotte")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Coloc")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.vertical, 28)
                }
                .clipShape(RoundedRectangle(cornerRadius: 0))
                .overlay(
                    RoundedRectangle(cornerRadius: 36)
                        .fill(Color.screenBackground)
                        .offset(y: 130)
                )

                VStack(spacing: 16) {
                    // Login section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Connexion")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.darkText)

                        AppTextField(placeholder: "Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)

                        AppTextField(placeholder: "Mot de passe", text: $password, isSecure: true)

                        if let err = loginError {
                            Text(err)
                                .font(.caption)
                                .foregroundColor(.coralRed)
                        }

                        PrimaryButton(
                            title: "Se connecter",
                            isLoading: authViewModel.isLoginLoading,
                            disabled: email.isEmpty || password.isEmpty
                        ) {
                            loginError = nil
                            authViewModel.login(email: email, password: password)
                        }
                    }

                    // Divider
                    HStack(spacing: 12) {
                        Rectangle().fill(Color.dividerColor).frame(height: 1)
                        Text("ou")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.lightText)
                        Rectangle().fill(Color.dividerColor).frame(height: 1)
                    }
                    .padding(.vertical, 8)

                    // Join section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Rejoindre une colocation")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.darkText)

                        Text("Entre ton code d'invitation pour rejoindre la coloc sans compte.")
                            .font(.system(size: 13))
                            .foregroundColor(.subtitleText)

                        AppTextField(placeholder: "Code d'invitation", text: $inviteCode)
                            .autocapitalization(.allCharacters)

                        if let err = joinError {
                            Text(err)
                                .font(.caption)
                                .foregroundColor(.coralRed)
                        }

                        PrimaryButton(
                            title: "Rejoindre",
                            isLoading: authViewModel.isJoinLoading,
                            disabled: inviteCode.isEmpty,
                            style: .dark
                        ) {
                            joinError = nil
                            authViewModel.joinColocation(inviteCode: inviteCode.trimmingCharacters(in: .whitespaces))
                        }
                    }

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .background(Color.screenBackground)
            }
        }
        .background(Color.screenBackground.ignoresSafeArea())
        .onChange(of: authViewModel.loginError) { _, err in
            loginError = err
        }
        .onChange(of: authViewModel.joinError) { _, err in
            joinError = err
        }
    }
}

// MARK: - Shared Input Components

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.borderColor, lineWidth: 1)
        )
        .font(.system(size: 15))
    }
}

enum ButtonStyle { case primary, dark }

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var disabled: Bool = false
    var style: ButtonStyle = .primary
    let action: () -> Void

    private var bgColor: Color {
        switch style {
        case .primary: return disabled ? Color.greenPrimary.opacity(0.4) : .greenPrimary
        case .dark:    return disabled ? Color.darkText.opacity(0.4) : .darkText
        }
    }

    var body: some View {
        Button(action: { if !isLoading && !disabled { action() } }) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(bgColor)
            .cornerRadius(18)
            .shadow(color: bgColor.opacity(0.4), radius: 10, x: 0, y: 4)
        }
        .disabled(disabled || isLoading)
    }
}
