import Foundation

@MainActor
final class ContributeViewModel: ObservableObject {
    @Published var cycleStatus: CycleStatusResponse?
    @Published var balance: BalanceResponse?
    @Published var isLoading = false
    @Published var isContributing = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var contributionAmount: String = ""
    @Published var defaultAmount: Double?

    private let repo: ContributionRepository
    private let colocationRepo: ColocationRepository
    private let tokenManager: TokenManager

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.repo = ContributionRepository(api: api)
        self.colocationRepo = ColocationRepository(api: api, tokenManager: tokenManager)
    }

    var colocationId: String? { tokenManager.colocationId }

    func load() {
        guard let id = colocationId else { return }
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                let detail = try await colocationRepo.getMyColocation()
                balance = detail.balance
                defaultAmount = detail.colocation.contributionAmount
                if let amt = detail.colocation.contributionAmount {
                    contributionAmount = String(format: "%.2f", amt)
                }
                cycleStatus = try? await repo.getCycleStatus(colocationId: id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func contribute() {
        guard let id = colocationId else { return }
        let amount = Double(contributionAmount.replacingOccurrences(of: ",", with: "."))
        Task {
            isContributing = true
            defer { isContributing = false }
            do {
                _ = try await repo.contribute(colocationId: id, amount: amount)
                successMessage = "Contribution enregistrée !"
                await load()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
