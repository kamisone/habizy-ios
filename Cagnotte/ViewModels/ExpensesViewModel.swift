import Foundation

@MainActor
final class ExpensesViewModel: ObservableObject {
    @Published var receipts: [ReceiptResponse] = []
    @Published var stats: ExpenseStatsResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let receiptRepo: ReceiptRepository
    private let tokenManager: TokenManager

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.receiptRepo = ReceiptRepository(api: api)
    }

    var colocationId: String? { tokenManager.colocationId }

    func load() {
        guard let id = colocationId else { return }
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                async let receiptsTask = receiptRepo.getReceipts(colocationId: id)
                async let statsTask = receiptRepo.getStats(colocationId: id)
                receipts = (try? await receiptsTask) ?? []
                stats = try? await statsTask
            }
        }
    }
}
