import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async { application.registerForRemoteNotifications() }
            }
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        UserDefaults.standard.set(token, forKey: "fcm_token")
        Task {
            let tokenManager = TokenManager()
            guard tokenManager.accessToken != nil else { return }
            let api = APIService.configure(tokenManager: tokenManager)
            try? await api.registerDevice(platform: "ios", token: token)
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        if let screen = userInfo["screen"] as? String {
            let entityId = userInfo["entityId"] as? String ?? userInfo["reportId"] as? String
            NotificationCenter.default.post(
                name: .didTapNotification,
                object: nil,
                userInfo: ["screen": screen, "entityId": entityId as Any]
            )
        }
    }
}

extension Notification.Name {
    static let didTapNotification = Notification.Name("didTapNotification")
}

@main
struct CagnotteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var tokenManager = TokenManager()
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        let bg = UIColor(red: 0xFB/255, green: 0xF7/255, blue: 0xF0/255, alpha: 1)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = bg
        appearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance

        UITabBar.appearance().isHidden = true
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(tokenManager)
                .environmentObject(authViewModel)
        }
    }
}
