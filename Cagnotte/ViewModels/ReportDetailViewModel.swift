import Foundation

@MainActor
final class ReportDetailViewModel: ObservableObject {
    @Published var detail: ReportDetailResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var currentUser: UserResponse?

    private let repo: ReportRepository
    private let api: APIService

    init(tokenManager: TokenManager) {
        let api = APIService.configure(tokenManager: tokenManager)
        self.api = api
        self.repo = ReportRepository(api: api)
    }

    var canEdit: Bool {
        guard let detail, let currentUser else { return false }
        return currentUser.id == detail.user.id || currentUser.isAdmin == true
    }

    func load(reportId: String) {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                currentUser = try? await api.getMe()
                detail = try await repo.getDetail(id: reportId)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func addComment(reportId: String, content: String) {
        Task {
            do {
                _ = try await repo.addComment(id: reportId, content: content)
                successMessage = "Commentaire ajoute"
                detail = try await repo.getDetail(id: reportId)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func updateReport(reportId: String, title: String, description: String, tags: [String]?) {
        Task {
            do {
                _ = try await repo.update(id: reportId, body: UpdateReportRequest(
                    title: title,
                    description: description.isEmpty ? nil : description,
                    tags: tags,
                    photoUrls: nil
                ))
                successMessage = "Signalement modifie"
                detail = try await repo.getDetail(id: reportId)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    @Published var deleted = false

    func deleteReport(reportId: String) {
        Task {
            do {
                try await repo.delete(id: reportId)
                deleted = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
