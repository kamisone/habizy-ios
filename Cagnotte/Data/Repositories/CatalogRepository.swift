import Foundation

@MainActor
final class CatalogRepository {
    private let api: APIService

    init(api: APIService) {
        self.api = api
    }

    func getArticles(colocationId: String) async throws -> [CatalogArticle] {
        try await api.getCatalogArticles(colocationId: colocationId)
    }

    func getCategories(colocationId: String) async throws -> [String] {
        try await api.getCatalogCategories(colocationId: colocationId)
    }

    func createArticle(name: String, category: String, colocationId: String) async throws -> CatalogArticle {
        let body = CreateCatalogArticleRequest(name: name, category: category, colocationId: colocationId)
        return try await api.createCatalogArticle(body: body)
    }

    func deleteArticle(id: String) async throws {
        try await api.deleteCatalogArticle(id: id)
    }
}
