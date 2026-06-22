import Foundation

@MainActor
final class ReportRepository {
    private let api: APIService

    init(api: APIService) {
        self.api = api
    }

    func getReports(colocationId: String, tag: String? = nil) async throws -> [ReportResponse] {
        try await api.getReports(colocationId: colocationId, tag: tag)
    }

    func create(body: CreateReportRequest) async throws -> ReportResponse {
        try await api.createReport(body: body)
    }

    func getDetail(id: String) async throws -> ReportDetailResponse {
        try await api.getReportDetail(id: id)
    }

    func update(id: String, body: UpdateReportRequest) async throws -> ReportDetailResponse {
        try await api.updateReport(id: id, body: body)
    }

    func addComment(id: String, content: String) async throws -> ReportCommentResponse {
        try await api.createReportComment(id: id, content: content)
    }

    func delete(id: String) async throws {
        try await api.deleteReport(id: id)
    }
}
