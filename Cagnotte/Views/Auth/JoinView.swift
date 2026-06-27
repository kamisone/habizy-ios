import SwiftUI

struct JoinView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var inviteCode = ""
    @State private var joinError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AuthLogoHeader()

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rejoindre une colocation")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.darkText)
                        Text("Entre le code d'invitation que tu as reçu")
                            .font(.system(size: 13))
                            .foregroundColor(.subtitleText)
                    }

                    AppTextField(placeholder: "Code d'invitation", text: $inviteCode)
                        .autocapitalization(.allCharacters)

                    if let err = joinError {
                        Text(err).font(.caption).foregroundColor(.coralRed)
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
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 40)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.screenBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: authViewModel.joinError) { err in joinError = err }
    }
}
