import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var vm: ProfileViewModel
    @State private var showChangePassword = false
    @State private var showMembers = false
    @State private var showCreateUser = false
    @State private var showAdmin = false
    @State private var showContribute = false
    @State private var currentPassword = ""
    @State private var newPassword = ""

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: ProfileViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Avatar + Name
                    if let user = vm.user {
                        avatarSection(user)
                    }

                    // Stats
                    statsRow

                    // Members preview
                    membersPreview

                    // Settings
                    settingsSection

                    // Admin section
                    if vm.isAdmin {
                        adminSection
                    }

                    // Logout
                    Button {
                        authViewModel.logout()
                    } label: {
                        Text("Se déconnecter")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.coralRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.coralRed.opacity(0.08))
                            .cornerRadius(18)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 100)
                }
                .padding(.top, 16)
            }
            .background(Color.screenBackground.ignoresSafeArea())
            .onAppear { vm.load() }
            .navigationDestination(isPresented: $showMembers) {
                MembersView(tokenManager: tokenManager)
            }
            .navigationDestination(isPresented: $showCreateUser) {
                CreateUserView(tokenManager: tokenManager)
            }
            .navigationDestination(isPresented: $showAdmin) {
                AdminSettingsView(tokenManager: tokenManager)
            }
            .navigationDestination(isPresented: $showContribute) {
                ContributeView(tokenManager: tokenManager)
            }
            .sheet(isPresented: $showChangePassword) {
                changePasswordSheet
            }
            .toast(message: Binding(
                get: { vm.errorMessage },
                set: { vm.errorMessage = $0 }
            ), type: .error)
            .toast(message: Binding(
                get: { vm.successMessage },
                set: { vm.successMessage = $0 }
            ), type: .success)
        }
    }

    private func avatarSection(_ user: UserResponse) -> some View {
        VStack(spacing: 10) {
            RoommateAvatar(user: user, size: 80, cornerRadius: 28, fontSize: 32)
            Text(user.name)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.darkText)
            Text(user.email)
                .font(.system(size: 14))
                .foregroundColor(.subtitleText)
        }
        .padding(.bottom, 4)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            ProfileStat(label: "Cotisations", value: vm.totalContributed.euroFormatted)
            ProfileStat(label: "Tickets", value: "\(vm.ticketCount)")
        }
        .padding(.horizontal, 18)
    }

    private var membersPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Colocataires")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.darkText)
                Spacer()
                Button("Voir tous") { showMembers = true }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.greenPrimary)
            }
            HStack(spacing: -8) {
                ForEach(vm.members.prefix(4), id: \.id) { member in
                    RoommateAvatar(user: member.user, size: 40, cornerRadius: 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
                if vm.members.count > 4 {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.lightCardBg)
                            .frame(width: 40, height: 40)
                        Text("+\(vm.members.count - 4)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.subtitleText)
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 18)
    }

    private var settingsSection: some View {
        VStack(spacing: 0) {
            SettingsRow(icon: "eurosign.circle", label: "Cotiser") {
                showContribute = true
            }
            Divider().padding(.leading, 56)
            SettingsRow(icon: "key", label: "Changer le mot de passe") {
                showChangePassword = true
            }
        }
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 18)
    }

    private var adminSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Administration")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.subtitleText)
                .padding(.horizontal, 18)
                .padding(.bottom, 6)

            VStack(spacing: 0) {
                SettingsRow(icon: "person.badge.plus", label: "Ajouter un colocataire") {
                    showCreateUser = true
                }
                Divider().padding(.leading, 56)
                SettingsRow(icon: "gearshape", label: "Paramètres admin") {
                    showAdmin = true
                }
            }
            .background(Color.white)
            .cornerRadius(22)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 18)
        }
    }

    private var changePasswordSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Changer le mot de passe")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.darkText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                AppTextField(placeholder: "Mot de passe actuel", text: $currentPassword, isSecure: true)
                AppTextField(placeholder: "Nouveau mot de passe", text: $newPassword, isSecure: true)

                PrimaryButton(title: "Modifier", disabled: currentPassword.isEmpty || newPassword.count < 6) {
                    vm.changePassword(current: currentPassword, new: newPassword)
                    showChangePassword = false
                    currentPassword = ""
                    newPassword = ""
                }

                Spacer()
            }
            .padding(24)
            .background(Color.screenBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { showChangePassword = false }
                }
            }
        }
    }
}

private struct ProfileStat: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.darkText)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.subtitleText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

private struct SettingsRow: View {
    let icon: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(.greenPrimary)
                    .frame(width: 28)
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.bodyText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.lightText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}
