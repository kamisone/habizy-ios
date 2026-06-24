import SwiftUI

struct MembersView: View {
    @StateObject private var vm: MembersViewModel
    @State private var memberToRemove: ColocationMemberResponse?
    @State private var showConfirm = false
    @State private var hasAppeared = false

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: MembersViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if vm.isLoading {
                    ProgressView().tint(.greenPrimary).padding(40)
                } else {
                    ForEach(vm.members) { member in
                        MemberRow(
                            member: member,
                            isCurrentUser: member.user.id == vm.currentUserId,
                            canRemove: vm.isAdmin && member.user.id != vm.currentUserId && member.role != "admin",
                            onRemove: {
                                memberToRemove = member
                                showConfirm = true
                            }
                        )
                    }
                }
            }
        }
        .background(Color.screenBackground.ignoresSafeArea())
        .navigationTitle("Colocataires")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if hasAppeared { Task { await vm.refresh() } } else { vm.load(); hasAppeared = true }
        }
        .alert("Retirer ce membre ?", isPresented: $showConfirm) {
            Button("Retirer", role: .destructive) {
                if let m = memberToRemove { vm.removeMember(userId: m.user.id) }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Cette action est irréversible.")
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

private struct MemberRow: View {
    let member: ColocationMemberResponse
    let isCurrentUser: Bool
    let canRemove: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            RoommateAvatar(user: member.user, size: 48, cornerRadius: 16)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(member.user.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.darkText)
                    if isCurrentUser {
                        Text("moi")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.greenPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.greenPrimary.opacity(0.12))
                            .cornerRadius(8)
                    }
                }
                Text(member.role == "admin" ? "Administrateur" : "Colocataire")
                    .font(.system(size: 12))
                    .foregroundColor(.subtitleText)
            }
            Spacer()
            if canRemove {
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.coralRed)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.white)
        .overlay(Divider().padding(.leading, 80), alignment: .bottom)
    }
}
