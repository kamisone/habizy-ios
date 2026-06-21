import Foundation

@MainActor
final class MembersViewModel: ObservableObject {
    @Published var members: [ColocationMemberResponse] = []
    @Published var colocationId: String = ""
    @Published var currentUserId: String = ""
    @Published var isAdmin = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let colocationRepo: ColocationRepository
    private let authRepo: AuthRepository

    init(tokenManager: TokenManager) {
        let api = APIService.configure(tokenManager: tokenManager)
        self.colocationRepo = ColocationRepository(api: api, tokenManager: tokenManager)
        self.authRepo = AuthRepository(api: api, tokenManager: tokenManager)
    }

    func load() {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                async let detailTask = colocationRepo.getMyColocation()
                async let meTask = authRepo.getMe()
                let detail = try await detailTask
                let me = try await meTask
                members = detail.members
                colocationId = detail.colocation.id
                currentUserId = me.id
                isAdmin = detail.members.first(where: { $0.user.id == me.id })?.role == "admin" || me.isAdmin
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func removeMember(userId: String) {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                try await colocationRepo.removeMember(colocationId: colocationId, userId: userId)
                members.removeAll { $0.user.id == userId }
                successMessage = "Membre retiré"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
