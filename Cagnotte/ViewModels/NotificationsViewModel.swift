import Foundation

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repo: NotificationRepository

    init(tokenManager: TokenManager) {
        let api = APIService.configure(tokenManager: tokenManager)
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

    func markRead(notification: NotificationResponse) {
        Task {
            do {
                try await repo.markRead(id: notification.id)
                if let idx = notifications.firstIndex(where: { $0.id == notification.id }) {
                    notifications[idx] = NotificationResponse(
                        id: notification.id,
                        type: notification.type,
                        message: notification.message,
                        isRead: true,
                        actor: notification.actor,
                        createdAt: notification.createdAt
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func markAllRead() {
        Task {
            for notif in notifications where !notif.isRead {
                try? await repo.markRead(id: notif.id)
            }
            notifications = notifications.map {
                NotificationResponse(id: $0.id, type: $0.type, message: $0.message, isRead: true, actor: $0.actor, createdAt: $0.createdAt)
            }
        }
    }
}
