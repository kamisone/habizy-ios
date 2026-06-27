import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var registerError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AuthLogoHeader()

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Créer mon compte")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.darkText)
                        Text("Vous serez administrateur de votre colocation")
                            .font(.system(size: 13))
                            .foregroundColor(.subtitleText)
                    }

                    AppTextField(placeholder: "Prénom et nom", text: $name)
                        .autocapitalization(.words)

                    AppTextField(placeholder: "Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    AppTextField(placeholder: "Mot de passe", text: $password, isSecure: true)

                    if let err = registerError {
                        Text(err).font(.caption).foregroundColor(.coralRed)
                    }

                    PrimaryButton(
                        title: "Créer mon compte",
                        isLoading: authViewModel.isRegisterLoading,
                        disabled: name.isEmpty || email.isEmpty || password.count < 6
                    ) {
                        registerError = nil
                        authViewModel.registerAdmin(
                            name: name.trimmingCharacters(in: .whitespaces),
                            email: email.trimmingCharacters(in: .whitespaces),
                            password: password
                        )
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
        .onChange(of: authViewModel.registerError) { err in registerError = err }
    }
}
