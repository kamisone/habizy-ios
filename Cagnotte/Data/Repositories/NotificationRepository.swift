import Foundation

@MainActor
final class NotificationRepository {
    private let api: APIService

    init(api: APIService) {
        self.api = api
    }

    func getAll() async throws -> [NotificationResponse] {
        try await api.getNotifications()
    }

    func markRead(id: String) async throws {
        try await api.markNotificationRead(id: id)
    }
}
