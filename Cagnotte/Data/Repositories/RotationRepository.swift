import Foundation

@MainActor
final class RotationRepository {
    private let api: APIService

    init(api: APIService) {
        self.api = api
    }

    func getRotation(colocationId: String) async throws -> [RotationEntryResponse] {
        try await api.getRotation(colocationId: colocationId)
    }

    func generate(colocationId: String) async throws -> [RotationEntryResponse] {
        try await api.generateRotation(colocationId: colocationId)
    }

    func swap(myId: String, theirId: String) async throws -> [RotationEntryResponse] {
        try await api.swapRotation(body: SwapRotationRequest(myRotationId: myId, theirRotationId: theirId))
    }
}
