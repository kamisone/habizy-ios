import Foundation

@MainActor
final class ReceiptViewModel: ObservableObject {
    @Published var receipts: [ReceiptResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repo: ReceiptRepository
    private let tokenManager: TokenManager

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.repo = ReceiptRepository(api: api)
    }

    var colocationId: String? { tokenManager.colocationId }

    func load() {
        guard let id = colocationId else { return }
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                receipts = try await repo.getReceipts(colocationId: id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
