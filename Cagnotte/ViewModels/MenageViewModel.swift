import Foundation

@MainActor
final class MenageViewModel: ObservableObject {
    @Published var weekData: MenageWeekResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUserId: String?

    private let api: APIService
    private let tokenManager: TokenManager

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        self.api = APIService.configure(tokenManager: tokenManager)
    }

    var colocationId: String? { tokenManager.colocationId }

    func load() {
        Task { await fetchData(showLoading: true) }
    }

    func refresh() async {
        await fetchData(showLoading: false)
    }

    func markDone(comment: String?) {
        guard let id = colocationId else { return }
        Task {
            do {
                try await api.markMenageDone(colocationId: id, comment: comment?.isEmpty == false ? comment : nil)
                await fetchData(showLoading: false)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func undoDone() {
        guard let id = colocationId else { return }
        Task {
            do {
                try await api.undoMenageDone(colocationId: id)
                await fetchData(showLoading: false)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func fetchData(showLoading: Bool) async {
        guard let id = colocationId else { return }
        if showLoading { isLoading = true }
        defer { isLoading = false }
        do {
            currentUserId = (try? await api.getMe())?.id
            weekData = try await api.getMenageWeek(colocationId: id)
        } catch {
            if showLoading { errorMessage = error.localizedDescription }
        }
    }
}
