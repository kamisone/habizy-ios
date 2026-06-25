import SwiftUI

struct ArticleStatsView: View {
    private let tokenManager: TokenManager
    private let repo: ReceiptRepository

    @Environment(\.dismiss) private var dismiss
    @State private var stats: [ArticleStat] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchQuery = ""

    private let dotColors: [Color] = [
        Color(red: 0.36, green: 0.61, blue: 0.96),
        Color(red: 1.00, green: 0.64, blue: 0.32),
        Color(red: 0.49, green: 0.85, blue: 0.65),
        Color(red: 1.00, green: 0.50, blue: 0.56),
        Color(red: 0.65, green: 0.55, blue: 0.98),
        Color(red: 1.00, green: 0.82, blue: 0.40),
        Color(red: 0.02, green: 0.84, blue: 0.63),
        Color(red: 0.94, green: 0.28, blue: 0.44),
    ]

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        self.repo = ReceiptRepository(api: APIService.configure(tokenManager: tokenManager))
    }

    var filtered: [ArticleStat] {
        guard !searchQuery.isEmpty else { return stats }
        return stats.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery) ||
            $0.category.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView().tint(.greenPrimary).padding(40)
            } else if let err = errorMessage {
                VStack(spacing: 12) {
                    Text(err)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.coralRed)
                    Button("Réessayer") {
                        Task { await load() }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.greenPrimary)
                    .cornerRadius(12)
                }
                .padding(40)
            } else {
                List(filtered) { stat in
                    ArticleStatRow(stat: stat, dotColor: dotColor(for: stat.name))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 5, leading: 18, bottom: 5, trailing: 18))
                }
                .listStyle(.plain)
                .searchable(text: $searchQuery, prompt: "Rechercher un article…")
            }
        }
        .navigationTitle("Articles achetés")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.screenBackground.ignoresSafeArea())
        .task { await load() }
        .onReceive(NotificationCenter.default.publisher(for: .popToTabRoot)) { _ in
            dismiss()
        }
    }

    private func load() async {
        guard let colId = tokenManager.colocationId else {
            errorMessage = "Aucune colocation trouvée"
            isLoading = false
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            stats = try await repo.getArticleStats(colocationId: colId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func dotColor(for name: String) -> Color {
        let idx = abs(name.hashValue) % dotColors.count
        return dotColors[idx]
    }
}

private struct ArticleStatRow: View {
    let stat: ArticleStat
    let dotColor: Color

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Circle()
                    .fill(dotColor)
                    .frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(stat.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.darkText)
                    Text("\(stat.totalQuantity)×  ·  \(stat.category)")
                        .font(.system(size: 12))
                        .foregroundColor(.subtitleText)
                }
                Spacer()
                Text(stat.totalAmount.euroFormatted)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.bodyText)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(dotColor.opacity(0.15))
                        .frame(height: 5)
                    Capsule()
                        .fill(dotColor)
                        .frame(width: geo.size.width * CGFloat(min(stat.fraction, 1)), height: 5)
                }
            }
            .frame(height: 5)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
