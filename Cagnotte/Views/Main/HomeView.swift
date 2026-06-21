import SwiftUI

struct HomeView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @StateObject private var vm: HomeViewModel
    @State private var showNotifications = false
    @State private var showRotation = false
    @State private var showShopping = false
    @State private var showDecideForMe = false
    @State private var showHistory = false
    @State private var showContribute = false

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: HomeViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch vm.state {
                case .loading:
                    loadingView
                case .error(let msg):
                    errorView(msg)
                case .noColocation:
                    SetupColocationView(onCreate: vm.createColocation)
                case .loaded(let data):
                    homeContent(data)
                }
            }
            .background(Color.screenBackground.ignoresSafeArea())
            .onAppear { vm.load() }
            .navigationDestination(isPresented: $showNotifications) {
                NotificationsView(tokenManager: tokenManager)
            }
            .navigationDestination(isPresented: $showRotation) {
                RotationView(tokenManager: tokenManager)
            }
            .navigationDestination(isPresented: $showDecideForMe) {
                DecideForMeView(tokenManager: tokenManager)
            }
            .navigationDestination(isPresented: $showHistory) {
                PurchaseHistoryView(tokenManager: tokenManager)
            }
            .navigationDestination(isPresented: $showContribute) {
                ContributeView(tokenManager: tokenManager)
            }
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView().tint(.greenPrimary)
            Spacer()
        }
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 16) {
            Text(msg)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.coralRed)
                .multilineTextAlignment(.center)
            Button("Réessayer") { vm.load() }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.greenPrimary)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .padding(24)
    }

    private func homeContent(_ data: HomeViewModel.HomeData) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bonjour,")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.subtitleText)
                        Text(data.userName)
                            .font(.system(size: 23, weight: .semibold, design: .rounded))
                            .foregroundColor(.darkText)
                    }
                    Spacer()
                    Button { showNotifications = true } label: {
                        ZStack(alignment: .topTrailing) {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white)
                                .frame(width: 44, height: 44)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            Image(systemName: "bell")
                                .foregroundColor(.darkText)
                                .font(.system(size: 20))
                                .frame(width: 44, height: 44)
                            Circle()
                                .fill(Color.coralRed)
                                .frame(width: 9, height: 9)
                                .padding(9)
                        }
                    }
                }
                .padding(.top, 8)

                // Balance card
                balanceCard(data)

                // Stat row
                HStack(spacing: 12) {
                    StatCard(label: "Mon tour", value: data.daysUntilTurn, valueColor: .darkText)
                    StatCard(label: "Dépensé ce mois", value: "-\(data.totalSpent.euroFormatted)", valueColor: .coralRed)
                }

                // Current shopper card
                Button { showRotation = true } label: {
                    HStack(spacing: 13) {
                        RoommateAvatar(
                            colorHex: data.currentShopperColor,
                            initial: data.currentShopperInitial,
                            size: 44,
                            cornerRadius: 15
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Aux courses cette semaine")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.subtitleText)
                            Text("C'est au tour de \(data.currentShopperName)")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.darkText)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.subtitleText)
                            .padding(8)
                            .background(Color.lightCardBg)
                            .cornerRadius(10)
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(22)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(.plain)

                // Shopping preview
                shoppingPreviewCard(data)

                // Quick actions
                HStack(spacing: 12) {
                    QuickActionCard(
                        icon: "dice",
                        label: "Décide pour moi",
                        bgColor: Color.purple.opacity(0.12),
                        iconColor: .purple
                    ) { showDecideForMe = true }
                    QuickActionCard(
                        icon: "clock.arrow.circlepath",
                        label: "Historique",
                        bgColor: Color.appBlue.opacity(0.10),
                        iconColor: .appBlue
                    ) { showHistory = true }
                }

                Spacer(minLength: 16)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
    }

    private func balanceCard(_ data: HomeViewModel.HomeData) -> some View {
        let progressFraction = data.totalContributed > 0
            ? min(1, max(0, Float(data.balance / data.totalContributed)))
            : 0

        return ZStack(alignment: .bottomLeading) {
            LinearGradient.greenGradient
            VStack(alignment: .leading, spacing: 0) {
                Text("Cagnotte commune")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                HStack(alignment: .bottom, spacing: 6) {
                    Text(String(format: "%.2f", data.balance).replacingOccurrences(of: ".", with: ","))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("€")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.bottom, 6)
                }
                .padding(.top, 6)
                Text("sur \(data.totalContributed.euroFormatted) · \(data.memberCount) colocataires")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.top, 4)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.22))
                            .frame(height: 10)
                        Capsule().fill(Color.orange)
                            .frame(width: geo.size.width * CGFloat(progressFraction), height: 10)
                    }
                }
                .frame(height: 10)
                .padding(.top, 18)

                Text("De quoi tenir encore environ 1 semaine")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.88))
                    .padding(.top, 9)
            }
            .padding(22)
        }
        .cornerRadius(28)
        .shadow(color: Color.greenDark.opacity(0.4), radius: 16, x: 0, y: 6)
    }

    private func shoppingPreviewCard(_ data: HomeViewModel.HomeData) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Liste de courses")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.darkText)
                Spacer()
                Text("\(data.shoppingItemCount) articles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.greenPrimary)
            }
            .padding(.bottom, 12)

            ForEach(data.shoppingPreview) { item in
                HStack(spacing: 11) {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.borderColor, lineWidth: 1.5)
                        .frame(width: 21, height: 21)
                    Text(item.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.bodyText)
                    Spacer()
                    Text("×\(item.quantity)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.subtitleText)
                }
                .padding(.vertical, 5)
            }

            let remaining = data.shoppingItemCount - data.shoppingPreview.count
            if remaining > 0 {
                Text("Voir les \(remaining) autres articles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.greenPrimary)
                    .padding(.top, 12)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .onTapGesture { showShopping = true }
    }
}

// MARK: - Supporting Views

private struct StatCard: View {
    let label: String
    let value: String
    let valueColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.subtitleText)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(valueColor)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

private struct QuickActionCard: View {
    let icon: String
    let label: String
    let bgColor: Color
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(bgColor)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 16))
                }
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.darkText)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Setup Colocation View

struct SetupColocationView: View {
    var onCreate: (String) -> Void
    @State private var colocationName = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 60)
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(LinearGradient.greenGradient)
                        .frame(width: 80, height: 80)
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 36, weight: .bold))
                }

                Text("Bienvenue !")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.darkText)

                Text("Créez votre colocation pour commencer.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.subtitleText)
                    .multilineTextAlignment(.center)

                VStack(spacing: 14) {
                    Text("Créer une colocation")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.darkText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    AppTextField(placeholder: "Nom de la colocation", text: $colocationName)

                    PrimaryButton(
                        title: "Créer",
                        disabled: colocationName.isEmpty
                    ) {
                        onCreate(colocationName.trimmingCharacters(in: .whitespaces))
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(22)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 24)
        }
    }
}
