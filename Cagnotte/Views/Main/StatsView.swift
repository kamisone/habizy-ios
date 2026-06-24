import SwiftUI

struct StatsView: View {
    @StateObject private var vm: StatsViewModel
    @State private var hasAppeared = false

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: StatsViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        ScrollView {
            if vm.isLoading {
                ProgressView().tint(.greenPrimary).padding(60)
            } else if let stats = vm.stats {
                VStack(spacing: 14) {
                    totalCard(stats)
                    perPersonCard(stats)
                    balanceCard(stats)
                    categoryCard(stats)
                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
            } else if let err = vm.errorMessage {
                Text(err)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.coralRed)
                    .padding(40)
            }
        }
        .background(Color.screenBackground.ignoresSafeArea())
        .navigationTitle("Statistiques")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if hasAppeared { Task { await vm.refresh() } } else { vm.load(); hasAppeared = true }
        }
    }

    private func totalCard(_ stats: ExpenseStatsResponse) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Total des depenses")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.subtitleText)
            Text(stats.totalSpent.euroFormatted)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.darkText)
            Text("\(stats.byRoommate.count) colocataires · \(stats.byCategory.count) categories")
                .font(.system(size: 12))
                .foregroundColor(.lightText)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private let chartColors: [Color] = [
        Color(hex: "#17A877"), Color(hex: "#3B82F6"), Color(hex: "#FFB020"),
        Color(hex: "#FF6B5E"), Color(hex: "#7C6BFF"), Color(hex: "#14B8A6"),
        Color(hex: "#F97316"), Color(hex: "#EC4899")
    ]

    private func perPersonCard(_ stats: ExpenseStatsResponse) -> some View {
        let maxAmount = stats.byRoommate.map { $0.total }.max() ?? 1

        return VStack(alignment: .leading, spacing: 14) {
            Text("Depenses par colocataire")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.darkText)

            ForEach(Array(stats.byRoommate.enumerated()), id: \.element.id) { index, roommate in
                let color = chartColors[index % chartColors.count]
                let name = roommate.user?.name ?? "Inconnu"
                let pct = stats.totalSpent > 0 ? Int(roommate.total / stats.totalSpent * 100) : 0

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(name).font(.system(size: 14, weight: .semibold)).foregroundColor(.darkText)
                        Spacer()
                        Text("\(roommate.total.euroFormatted) (\(pct)%)")
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(.darkText)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(color.opacity(0.12)).frame(height: 8)
                            Capsule().fill(color).frame(width: geo.size.width * CGFloat(roommate.total / max(maxAmount, 0.01)), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private func balanceCard(_ stats: ExpenseStatsResponse) -> some View {
        let count = max(stats.byRoommate.count, 1)
        let avg = stats.totalSpent / Double(count)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Equilibre des depenses")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.darkText)
            Text("Moyenne par personne : \(avg.euroFormatted)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.bodyText)

            ForEach(stats.byRoommate) { roommate in
                let name = roommate.user?.name ?? "Inconnu"
                let diff = roommate.total - avg
                HStack {
                    Text(name).font(.system(size: 14, weight: .medium)).foregroundColor(.bodyText)
                    Spacer()
                    Text(String(format: "%+.2f €", diff).replacingOccurrences(of: ".", with: ","))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(diff >= 0 ? .greenPrimary : .coralRed)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private func categoryCard(_ stats: ExpenseStatsResponse) -> some View {
        guard !stats.byCategory.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(VStack(alignment: .leading, spacing: 14) {
            Text("Depenses par categorie")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.darkText)

            ForEach(Array(stats.byCategory.enumerated()), id: \.element.id) { index, cat in
                let color = chartColors[index % chartColors.count]
                HStack(spacing: 8) {
                    Circle().fill(color).frame(width: 10, height: 10)
                    Text(cat.category).font(.system(size: 14, weight: .medium)).foregroundColor(.bodyText)
                    Spacer()
                    Text(cat.total.euroFormatted).font(.system(size: 14, weight: .semibold)).foregroundColor(.darkText)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2))
    }
}

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var stats: ExpenseStatsResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let receiptRepo: ReceiptRepository
    private let tokenManager: TokenManager

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.receiptRepo = ReceiptRepository(api: api)
    }

    func load() {
        guard let id = tokenManager.colocationId else { return }
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                stats = try await receiptRepo.getStats(colocationId: id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func refresh() async {
        guard let id = tokenManager.colocationId, !isLoading else { return }
        if let updated = try? await receiptRepo.getStats(colocationId: id) { stats = updated }
    }
}
