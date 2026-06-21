import Foundation

@MainActor
final class ContributionRepository {
    private let api: APIService

    init(api: APIService) {
        self.api = api
    }

    func contribute(colocationId: String, amount: Double?) async throws -> ContributionResponse {
        let body = CreateContributionRequest(colocationId: colocationId, amount: amount)
        return try await api.createContribution(body: body)
    }

    func getCycleStatus(colocationId: String) async throws -> CycleStatusResponse {
        try await api.getCycleStatus(colocationId: colocationId)
    }
}
