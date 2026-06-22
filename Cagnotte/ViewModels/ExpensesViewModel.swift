import Foundation

@MainActor
final class ExpensesViewModel: ObservableObject {
    @Published var receipts: [ReceiptResponse] = []
    @Published var stats: ExpenseStatsResponse?
    @Published var isLoading = false
    @Published var isAdmin = false
    @Published var isMyTurn = true
    @Published var currentPurchaserName = ""
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let receiptRepo: ReceiptRepository
    private let authRepo: AuthRepository
    private let rotationRepo: RotationRepository
    private let tokenManager: TokenManager

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.receiptRepo = ReceiptRepository(api: api)
        self.authRepo = AuthRepository(api: api, tokenManager: tokenManager)
        self.rotationRepo = RotationRepository(api: api)
    }

    var colocationId: String? { tokenManager.colocationId }

    func load() {
        Task { await fetchData(showLoading: true) }
    }

    func refresh() async {
        await fetchData(showLoading: false)
    }

    func deleteReceipt(id: String) {
        Task {
            do {
                try await receiptRepo.deleteReceipt(id: id)
                successMessage = "Ticket supprime"
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
        async let receiptsTask = receiptRepo.getReceipts(colocationId: id)
        async let statsTask = receiptRepo.getStats(colocationId: id)
        async let meTask = authRepo.getMe()
        async let rotationTask = rotationRepo.getRotation(colocationId: id)
        receipts = (try? await receiptsTask) ?? []
        stats = try? await statsTask
        let me = try? await meTask
        isAdmin = me?.isAdmin == true
        let rotation = (try? await rotationTask) ?? []
        let currentPurchaser = rotation.first { $0.status == "current" }
        isMyTurn = currentPurchaser == nil || currentPurchaser?.user.id == me?.id
        currentPurchaserName = currentPurchaser?.user.name ?? ""
    }
}
