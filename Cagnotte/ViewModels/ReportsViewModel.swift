import Foundation

@MainActor
final class ReportsViewModel: ObservableObject {
    @Published var reports: [ReportResponse] = []
    @Published var tags: [ReportTagResponse] = []
    @Published var isAdmin = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var tagFilter: String?

    private let repo: ReportRepository
    private let api: APIService
    private let tokenManager: TokenManager

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.api = api
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

    func createTag(title: String, color: String) {
        guard let id = colocationId else { return }
        Task {
            _ = try? await api.createReportTag(body: CreateTagRequest(title: title, color: color, colocationId: id))
            load()
        }
    }

    func deleteTag(id: String) {
        Task {
            try? await api.deleteReportTag(id: id)
            load()
        }
    }

    private func fetchData(showLoading: Bool) async {
        guard let id = colocationId else { return }
        if showLoading { isLoading = true }
        defer { isLoading = false }
        do {
            isAdmin = (try? await api.getMe())?.isAdmin == true
            tags = (try? await api.getReportTags(colocationId: id)) ?? []
            reports = try await repo.getReports(colocationId: id, tag: tagFilter)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
