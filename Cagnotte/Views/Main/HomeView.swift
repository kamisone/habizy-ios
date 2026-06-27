import SwiftUI

struct HomeView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @StateObject private var vm: HomeViewModel
    @State private var showNotifications = false
    @State private var showRotation = false
    @State private var showShopping = false
    @State private var showStats = false
    @State private var showHistory = false
    @State private var showMenage = false
    @State private var selectedReportId: ReportNavItem? = nil
    @State private var hasAppeared = false

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
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if hasAppeared { Task { await vm.refresh() } } else { vm.load(); hasAppeared = true }
            }
            .navigationDestination(isPresented: $showNotifications) {
                NotificationsView(tokenManager: tokenManager)
            }
            .navigationDestination(isPresented: $showRotation) {
                RotationView(tokenManager: tokenManager)
            }
            .navigationDestination(isPresented: $showStats) {
                StatsView(tokenManager: tokenManager)
            }
            .navigationDestination(isPresented: $showHistory) {
                PurchaseHistoryView(tokenManager: tokenManager)
            }
            .navigationDestination(isPresented: $showShopping) {
                ShoppingListView(tokenManager: tokenManager)
            }
            .navigationDestination(isPresented: $showMenage) {
                MenageView(tokenManager: tokenManager)
            }
            .navigationDestination(isPresented: Binding(get: { selectedReportId != nil }, set: { if !$0 { selectedReportId = nil } })) {
                if let item = selectedReportId {
                    ReportDetailView(reportId: item.id, tokenManager: tokenManager)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .popToTabRoot)) { _ in
                showNotifications = false
                showRotation = false
                showShopping = false
                showStats = false
                showHistory = false
                showMenage = false
                selectedReportId = nil
            }
        }
    }

    private var loadingView: some View {
        ScrollView {
            ShimmerHomeLoading()
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

                // Spending summary card
                spendingCard(data)

                // Les courses card
                lesCoursesSection(data)

                // Ménage section
                menageSectionView(data)

                // Signalements section
                if !data.recentReports.isEmpty {
                    signalementsSection(data.recentReports)
                }

                Spacer(minLength: 16)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
        .refreshable { await vm.refresh() }
    }

    // MARK: - Les courses card

    private func lesCoursesSection(_ data: HomeViewModel.HomeData) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.greenPrimary.opacity(0.12))
                    .frame(width: 38, height: 38)
                    .overlay {
                        Image(systemName: "cart")
                            .foregroundColor(.greenPrimary)
                            .font(.system(size: 16, weight: .medium))
                    }
                Text("Les courses")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.darkText)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Stat boxes: Mon tour + Mes dépenses
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mon tour")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.subtitleText)
                    Text(data.isUserDisabled ? "Désactivé" : (data.daysUntilTurn.isEmpty ? "—" : data.daysUntilTurn))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(data.isUserDisabled ? .subtitleText : .darkText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.screenBackground)
                .cornerRadius(14)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Mes dépenses")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.subtitleText)
                    Text("-\(data.mySpent.euroFormatted)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.coralRed)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.screenBackground)
                .cornerRadius(14)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            // Turn indicator
            Group {
                if data.isMyTurn {
                    Button { showRotation = true } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 13)
                                    .fill(Color.white.opacity(0.25))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "cart")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("C'est ton tour !")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Tu es le prochain a faire les courses")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(14)
                        .background(
                            LinearGradient(colors: [Color(hex: "#FFB020"), Color(hex: "#FF9800")],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                } else if !data.currentShopperName.isEmpty {
                    Button { showRotation = true } label: {
                        HStack(spacing: 12) {
                            Text(data.currentShopperInitial)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(RoundedRectangle(cornerRadius: 13).fill(Color.white.opacity(0.25)))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Aux courses")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.8))
                                Text(data.currentShopperName)
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(14)
                        .background(
                            LinearGradient(colors: [Color(hex: "#3B82F6"), Color(hex: "#1E40AF")],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button { showRotation = true } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 13)
                                    .fill(Color.borderColor.opacity(0.3))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.subtitleText)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Ordre non configuré")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.darkText)
                                Text("Configurer l'ordre de passage")
                                    .font(.system(size: 12))
                                    .foregroundColor(.subtitleText)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.subtitleText)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(14)
                        .background(Color.screenBackground)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            Divider().padding(.horizontal, 16).padding(.top, 14)

            // Shopping preview
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Articles manquants")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.darkText)
                    Spacer()
                    Text("\(data.shoppingItemCount) à acheter")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.greenPrimary)
                }
                .padding(.bottom, 10)

                if data.shoppingPreview.isEmpty {
                    Text("Aucun article manquant")
                        .font(.system(size: 13))
                        .foregroundColor(.subtitleText)
                } else {
                    ForEach(data.shoppingPreview) { item in
                        HStack(spacing: 10) {
                            Circle().fill(Color.greenPrimary).frame(width: 7, height: 7)
                            Text(item.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.bodyText)
                                .lineLimit(1)
                            Spacer()
                            Text("x\(item.quantity)")
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
                            .padding(.top, 10)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .onTapGesture { showShopping = true }

            Divider().padding(.horizontal, 16).padding(.top, 14)

            // Statistiques + Historique buttons
            HStack(spacing: 10) {
                courseActionButton(icon: "chart.bar", label: "Statistiques", color: .purple) { showStats = true }
                courseActionButton(icon: "clock.arrow.circlepath", label: "Historique", color: .appBlue) { showHistory = true }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private func courseActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 15))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.08))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Ménage section

    private func menageSectionView(_ data: HomeViewModel.HomeData) -> some View {
        Button { showMenage = true } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "bubbles.and.sparkles")
                                .foregroundColor(.orange)
                                .font(.system(size: 19))
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ménage")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.darkText)
                        Text("Cette semaine")
                            .font(.system(size: 12))
                            .foregroundColor(.subtitleText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.subtitleText)
                        .font(.system(size: 14, weight: .semibold))
                }

                if let menage = data.menage {
                    // Personal status pill
                    let done = menage.myDone
                    let statusColor: Color = done ? .green : .orange

                    HStack(spacing: 10) {
                        Image(systemName: done ? "checkmark.circle.fill" : "bubbles.and.sparkles")
                            .foregroundColor(statusColor)
                            .font(.system(size: 18))
                        Text(done ? "Tu as fait ton ménage !" : "À faire cette semaine")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(statusColor)
                        Spacer()
                        Text("\(menage.doneCount)/\(menage.totalCount)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(statusColor)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(14)
                    .padding(.top, 16)

                    // Progression
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Progression de la coloc")
                                .font(.system(size: 12))
                                .foregroundColor(.subtitleText)
                            Spacer()
                            Text("\(menage.doneCount) sur \(menage.totalCount)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.darkText)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 8)
                                let fraction = menage.totalCount > 0
                                    ? CGFloat(menage.doneCount) / CGFloat(menage.totalCount)
                                    : 0
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.green)
                                    .frame(width: geo.size.width * fraction, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.top, 14)

                    // Member avatars with status dots
                    if !menage.board.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(menage.board.prefix(7), id: \.userId) { member in
                                ZStack(alignment: .bottomTrailing) {
                                    RoommateAvatar(
                                        colorHex: member.colorHex ?? "#888888",
                                        initial: member.initial ?? String(member.name.prefix(1)).uppercased(),
                                        size: 38,
                                        cornerRadius: 12,
                                        fontSize: 14
                                    )
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 14, height: 14)
                                        .overlay {
                                            Circle()
                                                .fill(member.done ? Color.green : Color.gray.opacity(0.35))
                                                .padding(2)
                                        }
                                        .offset(x: 3, y: 3)
                                }
                            }
                            if menage.board.count > 7 {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.12))
                                    .frame(width: 38, height: 38)
                                    .overlay {
                                        Text("+\(menage.board.count - 7)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.subtitleText)
                                    }
                            }
                        }
                        .padding(.top, 14)
                    }

                    // Task description
                    if let task = menage.taskDescription, !task.isEmpty {
                        Divider()
                            .padding(.top, 14)
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "checkmark.square")
                                .font(.system(size: 13))
                                .foregroundColor(.subtitleText)
                                .padding(.top, 1)
                            Text(task)
                                .font(.system(size: 13))
                                .foregroundColor(.subtitleText)
                                .lineLimit(2)
                        }
                        .padding(.top, 10)
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(22)
            .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }


    // MARK: - Signalements section

    private func signalementsSection(_ reports: [ReportResponse]) -> some View {
        VStack(spacing: 0) {
            // Section header
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.coralRed.opacity(0.12))
                    .frame(width: 34, height: 34)
                    .overlay {
                        Image(systemName: "flag")
                            .foregroundColor(.coralRed)
                            .font(.system(size: 14))
                    }
                Text("Signalements récents")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.darkText)
                Spacer()
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)

            ForEach(Array(reports.enumerated()), id: \.element.id) { index, report in
                Button { selectedReportId = ReportNavItem(id: report.id) } label: {
                    HStack(spacing: 12) {
                        Group {
                            if let first = report.photoUrls?.first, let url = URL(string: first) {
                                AsyncImage(url: url) { phase in
                                    if case .success(let img) = phase {
                                        img.resizable().scaledToFill()
                                    } else {
                                        Color.lightCardBg
                                    }
                                }
                                .frame(width: 46, height: 46)
                                .clipShape(RoundedRectangle(cornerRadius: 13))
                            } else {
                                RoundedRectangle(cornerRadius: 13)
                                    .fill(Color.coralRed.opacity(0.1))
                                    .frame(width: 46, height: 46)
                                    .overlay {
                                        Image(systemName: "flag")
                                            .foregroundColor(.coralRed)
                                            .font(.system(size: 16))
                                    }
                            }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(report.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.darkText)
                                .lineLimit(1)
                            if let details = report.tagDetails?.prefix(3), !details.isEmpty {
                                HStack(spacing: 4) {
                                    ForEach(Array(details), id: \.title) { detail in
                                        let c = detail.color.flatMap { Color(hex: $0) } ?? tagColor(detail.title)
                                        Text(detail.title)
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(c)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(c.opacity(0.13))
                                            .cornerRadius(6)
                                    }
                                }
                            } else if let tags = report.tags?.prefix(3), !tags.isEmpty {
                                HStack(spacing: 4) {
                                    ForEach(Array(tags), id: \.self) { tag in
                                        let c = tagColor(tag)
                                        Text(tag)
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(c)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(c.opacity(0.13))
                                            .cornerRadius(6)
                                    }
                                }
                            }
                            Text("\(report.user.name) · \(formatTimeAgo(report.createdAt))")
                                .font(.system(size: 12))
                                .foregroundColor(.subtitleText)
                        }
                        Spacer()
                        if let count = report.commentCount, count > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "bubble.left")
                                    .font(.system(size: 11))
                                    .foregroundColor(.subtitleText)
                                Text("\(count)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.subtitleText)
                            }
                            .padding(.trailing, 6)
                        }
                        Image(systemName: "chevron.right")
                            .foregroundColor(.subtitleText)
                            .font(.system(size: 13))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                if index < reports.count - 1 {
                    Divider().padding(.horizontal, 16)
                }
            }

            Spacer(minLength: 12)
        }
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 2)
    }

    private func spendingCard(_ data: HomeViewModel.HomeData) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient.greenGradient
            VStack(alignment: .leading, spacing: 0) {
                Text("Dépenses de la coloc")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                CountingText(
                    targetValue: data.totalSpent,
                    font: .system(size: 48, weight: .bold, design: .rounded),
                    color: .white
                )
                .padding(.top, 6)
                Text("\(data.memberCount) colocataires · total cumulé")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.top, 4)
            }
            .padding(22)
        }
        .cornerRadius(28)
        .shadow(color: Color.greenDark.opacity(0.4), radius: 16, x: 0, y: 6)
    }

    private func shoppingPreviewCard(_ data: HomeViewModel.HomeData) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Articles manquants")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.darkText)
                Spacer()
                Text("\(data.shoppingItemCount) a acheter")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.greenPrimary)
            }
            .padding(.bottom, 12)

            ForEach(data.shoppingPreview) { item in
                HStack(spacing: 11) {
                    Circle()
                        .fill(Color.greenPrimary)
                        .frame(width: 8, height: 8)
                    Text(item.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.bodyText)
                    Spacer()
                    Text("x\(item.quantity)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.subtitleText)
                }
                .padding(.vertical, 6)
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
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Report Card

private struct ReportCardView: View {
    let report: ReportResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Rectangle().fill(Color.lightCardBg)
                if let first = report.photoUrls?.first, let url = URL(string: first) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                        } else if case .failure = phase {
                            placeholderContent
                        } else {
                            Color.lightCardBg
                        }
                    }
                } else {
                    placeholderContent
                }
            }
            .frame(width: 200, height: 110)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(report.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.darkText)
                    .lineLimit(1)

                if let tags = report.tags, !tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(tags.prefix(3), id: \.self) { tag in
                            let c = tagColor(tag)
                            Text(tag)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(c)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(c.opacity(0.12))
                                .cornerRadius(5)
                        }
                    }
                }

                HStack(spacing: 6) {
                    RoommateAvatar(user: report.user, size: 18, cornerRadius: 6, fontSize: 8)
                    Text(report.user.name)
                        .font(.system(size: 11))
                        .foregroundColor(.subtitleText)
                        .lineLimit(1)
                }

                HStack {
                    if let count = report.commentCount, count > 0 {
                        Text("\(count) commentaire\(count > 1 ? "s" : "")")
                            .font(.system(size: 10))
                            .foregroundColor(.greenPrimary)
                    } else {
                        Text("Aucun commentaire")
                            .font(.system(size: 10))
                            .foregroundColor(.subtitleText)
                    }
                    Spacer()
                    Text(formatTimeAgo(report.createdAt))
                        .font(.system(size: 10))
                        .foregroundColor(.lightText)
                }
            }
            .padding(12)
        }
        .frame(width: 200)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var placeholderContent: some View {
        VStack(spacing: 4) {
            Text("📋").font(.system(size: 28))
            Text("Pas de photo")
                .font(.system(size: 11))
                .foregroundColor(.subtitleText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .scrollDismissesKeyboard(.interactively)
    }
}
