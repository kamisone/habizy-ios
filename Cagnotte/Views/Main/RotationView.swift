import SwiftUI

struct RotationView: View {
    @StateObject private var vm: RotationViewModel
    @State private var swapMode = false
    @State private var selectedForSwap: RotationEntryResponse?

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
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .padding(.bottom, 40)
        }
        .background(Color.screenBackground.ignoresSafeArea())
        .navigationTitle("Rotation")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(swapMode ? "Annuler" : "Échanger") {
                    swapMode.toggle()
                    selectedForSwap = nil
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(swapMode ? .coralRed : .greenPrimary)
            }
        }
        .onAppear { vm.load() }
        .toast(message: Binding(
            get: { vm.errorMessage },
            set: { vm.errorMessage = $0 }
        ), type: .error)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.borderColor)
            Text("Aucune rotation")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.subtitleText)
            Text("La rotation sera générée par l'administrateur.")
                .font(.system(size: 14))
                .foregroundColor(.lightText)
                .multilineTextAlignment(.center)
        }
        .padding(60)
    }

    private var headerCard: some View {
        let current = vm.entries.first { $0.status == "current" }
        return VStack(alignment: .leading, spacing: 8) {
            Text("Cette semaine")
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
                let isMe = entry.user.id == vm.currentUserId
                let isSelected = selectedForSwap?.id == entry.id

                HStack(spacing: 14) {
                    Text("\(index + 1)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.lightText)
                        .frame(width: 20)

                    RoommateAvatar(user: entry.user, size: 40, cornerRadius: 13)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(entry.user.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.darkText)
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
                        if let start = entry.weekStart?.prefix(10), let end = entry.weekEnd?.prefix(10) {
                            Text("\(start) - \(end)")
                                .font(.system(size: 11))
                                .foregroundColor(.subtitleText)
                        }
                    }
                    Spacer()

                    if isCurrent {
                        Text("En cours")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.greenPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.greenPrimary.opacity(0.12))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    isSelected ? Color.appBlue.opacity(0.1) :
                    isCurrent ? Color.greenPrimary.opacity(0.05) : Color.white
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(isSelected ? Color.appBlue : Color.clear, lineWidth: 2)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    guard swapMode else { return }
                    if selectedForSwap == nil {
                        // Select my entry first, then swap target
                        if isMe { selectedForSwap = entry }
                    } else if let mine = selectedForSwap, mine.id != entry.id {
                        vm.swap(myEntry: mine, theirEntry: entry)
                        swapMode = false
                        selectedForSwap = nil
                    }
                }
                if index < vm.entries.count - 1 {
                    Divider().padding(.leading, 70)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

    }
}
