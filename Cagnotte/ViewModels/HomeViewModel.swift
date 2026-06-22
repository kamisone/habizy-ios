import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    struct HomeData {
        var userName: String
        var totalSpent: Double
        var mySpent: Double
        var memberCount: Int
        var currentShopperName: String
        var currentShopperColor: String
        var currentShopperInitial: String
        var shoppingItemCount: Int
        var shoppingPreview: [ShoppingItemResponse]
        var daysUntilTurn: String
        var isMyTurn: Bool
        var colocationId: String
    }

    enum HomeState {
        case loading
        case noColocation
        case loaded(HomeData)
        case error(String)
    }

    @Published var state: HomeState = .loading

    private let colocationRepo: ColocationRepository
    private let shoppingRepo: ShoppingRepository
    private let rotationRepo: RotationRepository
    private let receiptRepo: ReceiptRepository
    private let tokenManager: TokenManager

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.colocationRepo = ColocationRepository(api: api, tokenManager: tokenManager)
        self.shoppingRepo = ShoppingRepository(api: api)
        self.rotationRepo = RotationRepository(api: api)
        self.receiptRepo = ReceiptRepository(api: api)
    }

    func load() {
        Task { await fetchData(showLoading: true) }
    }

    func refresh() async {
        await fetchData(showLoading: false)
    }

    private func fetchData(showLoading: Bool = true) async {
        if showLoading { state = .loading }
        do {
            let detail = try await colocationRepo.getMyColocation()
            let colocationId = detail.colocation.id

            async let shoppingTask = shoppingRepo.getList(colocationId: colocationId)
            async let rotationTask = rotationRepo.getRotation(colocationId: colocationId)
            async let statsTask = receiptRepo.getStats(colocationId: colocationId)

            let shopping = (try? await shoppingTask) ?? []
            let rotation = (try? await rotationTask) ?? []
            let stats = try? await statsTask

            let me = try? await APIService.configure(tokenManager: tokenManager).getMe()
            let userName = me?.name ?? detail.members.first?.user.name ?? "Utilisateur"
            let userId = me?.id ?? detail.members.first?.user.id

            let currentEntry = rotation.first { $0.status == "current" }
            let currentShopperName = currentEntry?.user.name ?? "---"
            let currentShopperColor = currentEntry?.user.colorHex ?? "#888888"
            let currentShopperInitial = currentEntry?.user.initial ?? String(currentShopperName.prefix(1)).uppercased()

            let daysUntilTurn = computeDaysUntilTurn(rotation: rotation, userId: userId)
            let mySpent = stats?.byRoommate.first { $0.user?.id == userId }?.total ?? 0

            let data = HomeData(
                userName: userName,
                totalSpent: stats?.totalSpent ?? 0,
                mySpent: mySpent,
                memberCount: detail.members.count,
                currentShopperName: currentShopperName,
                currentShopperColor: currentShopperColor,
                currentShopperInitial: currentShopperInitial,
                shoppingItemCount: shopping.count,
                shoppingPreview: Array(shopping.prefix(3)),
                daysUntilTurn: daysUntilTurn,
                isMyTurn: currentEntry?.user.id == userId,
                colocationId: colocationId
            )
            state = .loaded(data)
        } catch let error as APIError {
            if case .serverError(let code, _) = error, code == 404 {
                state = .noColocation
            } else {
                state = .error(error.localizedDescription)
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func createColocation(name: String) {
        Task {
            state = .loading
            do {
                _ = try await colocationRepo.createColocation(name: name)
                await fetchData()
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    private func computeDaysUntilTurn(rotation: [RotationEntryResponse], userId: String?) -> String {
        guard let userId else { return "---" }
        let currentIndex = rotation.firstIndex { $0.status == "current" } ?? -1
        let myIndex = rotation.firstIndex { $0.user.id == userId } ?? -1
        guard currentIndex >= 0, myIndex >= 0 else { return "---" }
        let diff = myIndex >= currentIndex
            ? myIndex - currentIndex
            : rotation.count - currentIndex + myIndex
        switch diff {
        case 0: return "c'est ton tour"
        case 1: return "tu es le prochain"
        default: return "dans \(diff) tours"
        }
    }
}
