import Foundation

@MainActor
final class ShoppingViewModel: ObservableObject {
    @Published var items: [ShoppingItemResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var members: [UserResponse] = []
    @Published var catalogArticles: [CatalogArticle] = []
    @Published var isAdmin = false

    private let repo: ShoppingRepository
    private let colocationRepo: ColocationRepository
    private let catalogRepo: CatalogRepository
    private let authRepo: AuthRepository
    private let tokenManager: TokenManager

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.repo = ShoppingRepository(api: api)
        self.colocationRepo = ColocationRepository(api: api, tokenManager: tokenManager)
        self.catalogRepo = CatalogRepository(api: api)
        self.authRepo = AuthRepository(api: api, tokenManager: tokenManager)
    }

    var colocationId: String? { tokenManager.colocationId }

    var uncheckedItems: [ShoppingItemResponse] { items.filter { !$0.isChecked } }
    var checkedItems: [ShoppingItemResponse] { items.filter { $0.isChecked } }

    func load() {
        Task { await fetchData(showLoading: true) }
    }

    func refresh() async {
        await fetchData(showLoading: false)
    }

    private func fetchData(showLoading: Bool) async {
        guard let id = colocationId else { return }
        if showLoading { isLoading = true }
        defer { isLoading = false }
        do {
            async let itemsTask = repo.getList(colocationId: id)
            async let detailTask = colocationRepo.getMyColocation()
            async let catalogTask = catalogRepo.getArticles(colocationId: id)
            async let meTask = authRepo.getMe()
            items = try await itemsTask
            let detail = try? await detailTask
            members = detail?.members.map { $0.user } ?? []
            catalogArticles = (try? await catalogTask) ?? []
            isAdmin = (try? await meTask)?.isAdmin ?? false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addItem(name: String, quantity: Int, assigneeId: String?) {
        guard let id = colocationId else { return }
        Task {
            do {
                let item = try await repo.addItem(name: name, quantity: quantity, assigneeId: assigneeId, colocationId: id)
                items.insert(item, at: 0)
                successMessage = "Article ajoute"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func toggle(item: ShoppingItemResponse) {
        Task {
            do {
                let updated = try await repo.toggle(id: item.id)
                if let idx = items.firstIndex(where: { $0.id == item.id }) {
                    items[idx] = updated
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func delete(item: ShoppingItemResponse) {
        Task {
            do {
                try await repo.delete(id: item.id)
                items.removeAll { $0.id == item.id }
                successMessage = "Article retire"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func addCatalogArticle(name: String, category: String) {
        guard let id = colocationId else { return }
        Task {
            do {
                _ = try await catalogRepo.createArticle(name: name, category: category, colocationId: id)
                catalogArticles = try await catalogRepo.getArticles(colocationId: id)
                successMessage = "Article ajoute au catalogue"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteCatalogArticle(id: String) {
        guard let colId = colocationId else { return }
        Task {
            do {
                try await catalogRepo.deleteArticle(id: id)
                catalogArticles = try await catalogRepo.getArticles(colocationId: colId)
                successMessage = "Article retire du catalogue"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
