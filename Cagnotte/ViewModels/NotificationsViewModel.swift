import Foundation

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repo: NotificationRepository
    private let api: APIService

    init(tokenManager: TokenManager) {
        let api = APIService.configure(tokenManager: tokenManager)
        self.api = api
        self.repo = NotificationRepository(api: api)
    }

    var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    func load() {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                notifications = try await repo.getAll()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func refresh() async {
        guard !isLoading else { return }
        if let updated = try? await repo.getAll() { notifications = updated }
    }

    func markRead(notification: NotificationResponse) {
        Task {
            do {
                try await repo.markRead(id: notification.id)
                if let idx = notifications.firstIndex(where: { $0.id == notification.id }) {
                    var updated = notifications
                    updated[idx] = NotificationResponse(
                        id: notification.id,
                        type: notification.type,
                        title: notification.title,
                        body: notification.body,
                        message: notification.message,
                        isRead: true,
                        readAt: ISO8601DateFormatter().string(from: Date()),
                        actor: notification.actor,
                        data: notification.data,
                        createdAt: notification.createdAt
                    )
                    notifications = updated
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func markAllRead() {
        Task {
            do {
                try await api.markAllNotificationsRead()
                notifications = notifications.map {
                    NotificationResponse(
                        id: $0.id, type: $0.type, title: $0.title, body: $0.body,
                        message: $0.message, isRead: true,
                        readAt: ISO8601DateFormatter().string(from: Date()),
                        actor: $0.actor, data: $0.data, createdAt: $0.createdAt
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
