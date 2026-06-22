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

    func createReceipt(colocationId: String, store: String, date: String, time: String? = nil, totalAmount: Double, photoUrl: String? = nil, items: [CreateReceiptItemRequest]) async throws -> ReceiptResponse {
        let body = CreateReceiptRequest(colocationId: colocationId, store: store, date: date, time: time, totalAmount: totalAmount, photoUrl: photoUrl, items: items)
        return try await api.createReceipt(body: body)
    }

    func getStats(colocationId: String) async throws -> ExpenseStatsResponse {
        try await api.getExpenseStats(colocationId: colocationId)
    }

    func deleteReceipt(id: String) async throws {
        try await api.deleteReceipt(id: id)
    }

    func getArticleCatalog(colocationId: String) async throws -> [ArticleSuggestion] {
        try await api.getArticleCatalog(colocationId: colocationId)
    }

    func getArticleStats(colocationId: String) async throws -> [ArticleStat] {
        try await api.getArticleStats(colocationId: colocationId)
    }
}
