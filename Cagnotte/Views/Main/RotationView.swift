import SwiftUI

struct RotationView: View {
    @StateObject private var vm: RotationViewModel

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: RotationViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if vm.isLoading {
                    ProgressView().tint(.greenPrimary).padding(40)
                } else if vm.entries.isEmpty {
                    emptyState
                } else {
                    headerCard
                    entriesList
                    if vm.isAdmin && vm.hasReordered {
                        saveButton
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .padding(.bottom, 40)
        }
        .background(Color.screenBackground.ignoresSafeArea())
        .navigationTitle("Rotation")
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

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.borderColor)
            Text("Aucun ordre de passage")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.subtitleText)
            if vm.isAdmin {
                Text("Generez l'ordre pour lancer la rotation.")
                    .font(.system(size: 14))
                    .foregroundColor(.lightText)
                    .multilineTextAlignment(.center)
                Button {
                    vm.generate()
                } label: {
                    Text("Generer l'ordre")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 13)
                        .background(Color.greenPrimary)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
            } else {
                Text("L'administrateur doit generer l'ordre.")
                    .font(.system(size: 14))
                    .foregroundColor(.lightText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(60)
    }

    private var headerCard: some View {
        let current = vm.entries.first { $0.status == "current" }
        return VStack(alignment: .leading, spacing: 8) {
            Text("Prochain aux courses")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
            if let entry = current {
                HStack(spacing: 12) {
                    RoommateAvatar(
                        colorHex: entry.user.colorHex ?? "#888",
                        initial: entry.user.initial ?? String(entry.user.name.prefix(1)).uppercased(),
                        size: 48,
                        cornerRadius: 16
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("C'est au tour de")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                        Text(entry.user.name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }
            Text("Le tour avance apres l'ajout d'un ticket")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient.greenGradient)
        .cornerRadius(22)
        .shadow(color: Color.greenDark.opacity(0.3), radius: 10, x: 0, y: 4)
    }

    private var entriesList: some View {
        VStack(spacing: 0) {
            ForEach(Array(vm.entries.enumerated()), id: \.element.id) { index, entry in
                let isCurrent = entry.status == "current"
                let isDisabled = entry.isDisabled == true
                let isMe = entry.user.id == vm.currentUserId

                HStack(spacing: 10) {
                    Text("\(index + 1)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.lightText)
                        .frame(width: 20)

                    RoommateAvatar(user: entry.user, size: 40, cornerRadius: 13)
                        .opacity(isDisabled ? 0.45 : 1)

                    HStack(spacing: 6) {
                        Text(entry.user.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isDisabled ? .subtitleText : .darkText)
                        if isMe {
                            Text("moi")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.greenPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.greenPrimary.opacity(0.12))
                                .cornerRadius(6)
                        }
                    }
                    Spacer()

                    if vm.isAdmin {
                        Button { vm.toggleMemberActive(userId: entry.user.id) } label: {
                            Text(isDisabled ? "Activer" : "Desactiver")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(isDisabled ? .greenPrimary : Color(hex: "#FFB020"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(isDisabled ? Color.greenPrimary.opacity(0.12) : Color(hex: "#FFB020").opacity(0.12))
                                .cornerRadius(20)
                        }
                        .buttonStyle(.plain)

                        if index > 0 {
                            Button { vm.moveEntry(from: index, to: index - 1) } label: {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.darkText)
                                    .frame(width: 28, height: 28)
                                    .background(Color.lightCardBg)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        if index < vm.entries.count - 1 {
                            Button { vm.moveEntry(from: index, to: index + 1) } label: {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.darkText)
                                    .frame(width: 28, height: 28)
                                    .background(Color.lightCardBg)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if isDisabled {
                        Text("Absent")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "#FFB020"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#FFB020").opacity(0.12))
                            .cornerRadius(8)
                    } else if isCurrent {
                        Text("En cours")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.greenPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.greenPrimary.opacity(0.12))
                            .cornerRadius(8)
                    } else {
                        Text("A venir")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.subtitleText)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isCurrent ? Color.greenPrimary.opacity(0.05) : Color.white)

                if index < vm.entries.count - 1 {
                    Divider().padding(.leading, 70)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var saveButton: some View {
        Button {
            vm.saveOrder()
        } label: {
            if vm.isSaving {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.greenPrimary)
                    .cornerRadius(18)
            } else {
                Text("Sauvegarder l'ordre")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.greenPrimary)
                    .cornerRadius(18)
            }
        }
        .buttonStyle(.plain)
        .disabled(vm.isSaving)
    }
}
