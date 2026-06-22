import Foundation

@MainActor
final class ContributionRepository {
    init(api: APIService) {}

    func contribute(colocationId: String, amount: Double?) async throws -> ContributionResponse {
        throw URLError(.unsupportedURL)
    }

    func getCycleStatus(colocationId: String) async throws -> CycleStatusResponse {
        throw URLError(.unsupportedURL)
    }
}
