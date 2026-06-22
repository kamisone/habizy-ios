import Foundation

@MainActor
final class ColocationRepository {
    private let api: APIService
    private let tokenManager: TokenManager

    init(api: APIService, tokenManager: TokenManager) {
        self.api = api
        self.tokenManager = tokenManager
    }

    func getMyColocation() async throws -> ColocationDetailResponse {
        let detail = try await api.getMyColocation()
        tokenManager.saveColocationId(detail.colocation.id)
        return detail
    }

    func createColocation(name: String) async throws -> ColocationResponse {
        let body = CreateColocationRequest(name: name)
        return try await api.createColocation(body: body)
    }

    func updateColocation(id: String, name: String? = nil, spendingGapThreshold: Double? = nil, notificationsEnabled: Bool? = nil) async throws -> ColocationResponse {
        let body = UpdateColocationRequest(name: name, spendingGapThreshold: spendingGapThreshold, notificationsEnabled: notificationsEnabled)
        return try await api.updateColocation(id: id, body: body)
    }

    func addMember(colocationId: String, name: String, email: String, password: String?, colorHex: String?) async throws -> CreateUserResponse {
        let body = AddMemberRequest(name: name, email: email, password: password, colorHex: colorHex)
        return try await api.addMember(colocationId: colocationId, body: body)
    }

    func removeMember(colocationId: String, userId: String) async throws {
        try await api.removeMember(colocationId: colocationId, userId: userId)
    }
}
