import Foundation

@MainActor
final class ContributeViewModel: ObservableObject {
    @Published var cycleStatus: CycleStatusResponse?
    @Published var isLoading = false
    @Published var isContributing = false
    @Published var errorMessage: String? = "Fonctionnalité supprimée"
    @Published var successMessage: String?
    @Published var contributionAmount: String = ""

    init(tokenManager: TokenManager) {}

    func load() {}
    func contribute() {}
}
