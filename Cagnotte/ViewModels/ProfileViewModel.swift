import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: UserResponse?
    @Published var colocation: ColocationResponse?
    @Published var members: [ColocationMemberResponse] = []
    @Published var balance: BalanceResponse?
    @Published var cycleStatus: CycleStatusResponse?
    @Published var receipts: [ReceiptResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let authRepo: AuthRepository
    private let colocationRepo: ColocationRepository
    private let contributionRepo: ContributionRepository
    private let receiptRepo: ReceiptRepository
    private let tokenManager: TokenManager

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.authRepo = AuthRepository(api: api, tokenManager: tokenManager)
        self.colocationRepo = ColocationRepository(api: api, tokenManager: tokenManager)
        self.contributionRepo = ContributionRepository(api: api)
        self.receiptRepo = ReceiptRepository(api: api)
    }

    var colocationId: String? { tokenManager.colocationId }

    func load() {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                async let meTask = authRepo.getMe()
                async let detailTask = colocationRepo.getMyColocation()
                user = try await meTask
                let detail = try await detailTask
                colocation = detail.colocation
                members = detail.members
                balance = detail.balance
                if let cid = colocationId {
                    receipts = (try? await receiptRepo.getReceipts(colocationId: cid)) ?? []
                    cycleStatus = try? await contributionRepo.getCycleStatus(colocationId: cid)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func changePassword(current: String, new: String) {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                try await authRepo.changePassword(current: current, new: new)
                successMessage = "Mot de passe modifié avec succès"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    var totalContributed: Double { balance?.totalContributed ?? 0 }
    var ticketCount: Int { receipts.count }
    var isAdmin: Bool { members.first(where: { $0.user.id == user?.id })?.role == "admin" || user?.isAdmin == true }
}
