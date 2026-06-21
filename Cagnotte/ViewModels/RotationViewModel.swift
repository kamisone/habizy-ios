import Foundation

@MainActor
final class RotationViewModel: ObservableObject {
    @Published var entries: [RotationEntryResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUserId: String = ""
    @Published var swapTargetId: String?

    private let repo: RotationRepository
    private let authRepo: AuthRepository
    private let tokenManager: TokenManager

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.repo = RotationRepository(api: api)
        self.authRepo = AuthRepository(api: api, tokenManager: tokenManager)
    }

    var colocationId: String? { tokenManager.colocationId }

    func load() {
        guard let id = colocationId else { return }
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                async let rotationTask = repo.getRotation(colocationId: id)
                async let meTask = authRepo.getMe()
                entries = try await rotationTask
                let me = try await meTask
                currentUserId = me.id
            } catch {
                errorMessage = error.localizedDescription
            }
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
}
