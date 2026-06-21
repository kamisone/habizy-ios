import Foundation

@MainActor
final class ShoppingViewModel: ObservableObject {
    @Published var items: [ShoppingItemResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var members: [UserResponse] = []

    private let repo: ShoppingRepository
    private let colocationRepo: ColocationRepository
    private let tokenManager: TokenManager

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.repo = ShoppingRepository(api: api)
        self.colocationRepo = ColocationRepository(api: api, tokenManager: tokenManager)
    }

    var colocationId: String? { tokenManager.colocationId }

    var uncheckedItems: [ShoppingItemResponse] { items.filter { !$0.isChecked } }
    var checkedItems: [ShoppingItemResponse] { items.filter { $0.isChecked } }

    func load() {
        guard let id = colocationId else { return }
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                async let itemsTask = repo.getList(colocationId: id)
                async let detailTask = colocationRepo.getMyColocation()
                items = try await itemsTask
                let detail = try? await detailTask
                members = detail?.members.map { $0.user } ?? []
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func addItem(name: String, quantity: Int, assigneeId: String?) {
        guard let id = colocationId else { return }
        Task {
            do {
                let item = try await repo.addItem(name: name, quantity: quantity, assigneeId: assigneeId, colocationId: id)
                items.insert(item, at: 0)
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
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
