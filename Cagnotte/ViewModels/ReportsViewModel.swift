import Foundation

@MainActor
final class ReportsViewModel: ObservableObject {
    @Published var reports: [ReportResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var tagFilter: String?

    private let repo: ReportRepository
    private let tokenManager: TokenManager

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.repo = ReportRepository(api: api)
    }

    var colocationId: String? { tokenManager.colocationId }

    func load() {
        Task { await fetchData(showLoading: true) }
    }

    func refresh() async {
        await fetchData(showLoading: false)
    }

    func setTagFilter(_ tag: String?) {
        tagFilter = tag
        load()
    }

    private func fetchData(showLoading: Bool) async {
        guard let id = colocationId else { return }
        if showLoading { isLoading = true }
        defer { isLoading = false }
        do {
            reports = try await repo.getReports(colocationId: id, tag: tagFilter)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
