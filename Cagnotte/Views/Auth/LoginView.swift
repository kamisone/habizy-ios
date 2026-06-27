import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var loginError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AuthLogoHeader()

                VStack(alignment: .leading, spacing: 14) {
                    Text("Connexion")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.darkText)

                    AppTextField(placeholder: "Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    AppTextField(placeholder: "Mot de passe", text: $password, isSecure: true)

                    if let err = loginError {
                        Text(err).font(.caption).foregroundColor(.coralRed)
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
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 40)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.screenBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: authViewModel.loginError) { err in loginError = err }
    }
}

// MARK: - Shared Auth Components

struct AuthLogoHeader: View {
    var body: some View {
        VStack(spacing: 10) {
            if let uiImage = UIImage(named: "logo_habizy") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            Text("Habizy")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "#17C97E"),
                            Color(hex: "#00B4D8"),
                            Color(hex: "#6C63FF"),
                            Color(hex: "#E040A0"),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(.top, 32)
        .padding(.bottom, 16)
    }
}

// MARK: - Shared Input Components

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    @State private var showPassword = false

    var body: some View {
        HStack {
            Group {
                if isSecure && !showPassword {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.system(size: 15))
            .foregroundColor(.darkText)
            .tint(.greenPrimary)

            if isSecure {
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.subtitleText)
                        .font(.system(size: 15))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }
}

enum AppButtonStyle { case primary, dark }

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var disabled: Bool = false
    var style: AppButtonStyle = .primary
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
