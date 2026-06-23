import Foundation
import UserNotifications
import BackgroundTasks

final class NotificationPoller {
    static let shared = NotificationPoller()
    static let bgTaskId = "com.example.cagnotte.notificationPoll"

    private let lastIdKey = "last_notification_id"
    private var timer: Timer?

    private init() {}

    var lastNotificationId: String? {
        get { UserDefaults.standard.string(forKey: lastIdKey) }
        set { UserDefaults.standard.set(newValue, forKey: lastIdKey) }
    }

    // MARK: - Foreground polling

    func startForegroundPolling(interval: TimeInterval = 60) {
        stopForegroundPolling()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { await self?.poll() }
        }
        Task { await poll() }
    }

    func stopForegroundPolling() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Background task registration

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.bgTaskId, using: nil) { task in
            self.handleBackgroundTask(task as! BGAppRefreshTask)
        }
    }

    func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: Self.bgTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleBackgroundTask(_ task: BGAppRefreshTask) {
        scheduleBackgroundTask()

        let pollTask = Task {
            await poll()
        }

        task.expirationHandler = { pollTask.cancel() }

        Task {
            _ = await pollTask.result
            task.setTaskCompleted(success: true)
        }
    }

    // MARK: - Core polling logic

    @MainActor
    func poll() async {
        guard UserDefaults.standard.string(forKey: "access_token") != nil else { return }

        let api = APIService()
        do {
            let newNotifications: [NotificationResponse]
            if let lastId = lastNotificationId {
                newNotifications = try await api.getNotificationsSince(lastId: lastId)
            } else {
                newNotifications = try await api.getNotifications()
            }

            for notification in newNotifications {
                showLocalNotification(notification)
            }

            if let last = newNotifications.last {
                lastNotificationId = last.id
            }
        } catch {
            print("NotificationPoller: poll failed - \(error)")
        }
    }

    // MARK: - Local notification display

    private func showLocalNotification(_ notification: NotificationResponse) {
        let content = UNMutableNotificationContent()
        content.title = "Habizy"
        content.body = notification.message
        content.sound = .default
        content.userInfo = ["notificationId": notification.id]

        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("NotificationPoller: failed to show - \(error)") }
        }
    }

    // MARK: - Permission

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error { print("NotificationPoller: permission error - \(error)") }
        }
    }
}
