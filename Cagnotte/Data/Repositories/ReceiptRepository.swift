import Foundation

@MainActor
final class ReceiptRepository {
    private let api: APIService

    init(api: APIService) {
        self.api = api
    }

    func getReceipts(colocationId: String) async throws -> [ReceiptResponse] {
        try await api.getReceipts(colocationId: colocationId)
    }

    func createReceipt(colocationId: String, store: String, date: String, totalAmount: Double, items: [CreateReceiptItemRequest]) async throws -> ReceiptResponse {
        let body = CreateReceiptRequest(colocationId: colocationId, store: store, date: date, totalAmount: totalAmount, items: items)
        return try await api.createReceipt(body: body)
    }

    func getStats(colocationId: String) async throws -> ExpenseStatsResponse {
        try await api.getExpenseStats(colocationId: colocationId)
    }
}
