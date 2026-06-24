import Foundation

@MainActor
final class RotationViewModel: ObservableObject {
    @Published var entries: [RotationEntryResponse] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var hasReordered = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var currentUserId: String = ""
    @Published var isAdmin = false

    private let repo: RotationRepository
    private let authRepo: AuthRepository
    private let api: APIService
    private let tokenManager: TokenManager

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.api = api
        self.repo = RotationRepository(api: api)
        self.authRepo = AuthRepository(api: api, tokenManager: tokenManager)
    }

    var colocationId: String? { tokenManager.colocationId }

    func load() {
        Task {
            isLoading = true
            defer { isLoading = false }
            await fetchData()
        }
    }

    func refresh() async {
        guard !isLoading else { return }
        await fetchData()
    }

    private func fetchData() async {
        guard let id = colocationId else { return }
        do {
            async let rotationTask = repo.getRotation(colocationId: id)
            async let meTask = authRepo.getMe()
            entries = try await rotationTask
            let me = try await meTask
            currentUserId = me.id
            isAdmin = me.isAdmin
            hasReordered = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func generate() {
        guard let id = colocationId else { return }
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                entries = try await repo.generate(colocationId: id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func moveEntry(from: Int, to: Int) {
        guard from >= 0, to >= 0, from < entries.count, to < entries.count else { return }
        var list = entries
        let item = list.remove(at: from)
        list.insert(item, at: to)
        entries = list
        hasReordered = true
    }

    func toggleMemberActive(userId: String) {
        guard let id = colocationId else { return }
        Task {
            do {
                try await api.toggleMemberActive(colocationId: id, userId: userId)
                successMessage = "Statut mis a jour"
                load()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func saveOrder() {
        guard let id = colocationId else { return }
        let userIds = entries.map { $0.user.id }
        Task {
            isSaving = true
            defer { isSaving = false }
            do {
                _ = try await api.setPurchaseOrder(colocationId: id, userIds: userIds)
                successMessage = "Ordre sauvegarde"
                load()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func swap(myEntry: RotationEntryResponse, theirEntry: RotationEntryResponse) {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                entries = try await repo.swap(myId: myEntry.id, theirId: theirEntry.id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    var myEntry: RotationEntryResponse? {
        entries.first { $0.user.id == currentUserId }
    }

    var isMyTurn: Bool {
        guard let current = entries.first(where: { $0.status == "current" }) else { return true }
        return current.user.id == currentUserId
    }
}
