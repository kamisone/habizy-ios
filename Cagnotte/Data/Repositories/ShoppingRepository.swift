import Foundation

@MainActor
final class ShoppingRepository {
    private let api: APIService

    init(api: APIService) {
        self.api = api
    }

    func getList(colocationId: String) async throws -> [ShoppingItemResponse] {
        try await api.getShoppingList(colocationId: colocationId)
    }

    func addItem(name: String, quantity: Int, assigneeId: String?, colocationId: String) async throws -> ShoppingItemResponse {
        let body = CreateShoppingItemRequest(name: name, quantity: quantity, assigneeId: assigneeId, colocationId: colocationId)
        return try await api.createShoppingItem(body: body)
    }

    func toggle(id: String) async throws -> ShoppingItemResponse {
        try await api.toggleShoppingItem(id: id)
    }

    func delete(id: String) async throws {
        try await api.deleteShoppingItem(id: id)
    }
}
