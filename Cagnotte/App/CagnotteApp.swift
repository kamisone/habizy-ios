import SwiftUI

@main
struct CagnotteApp: App {
    @StateObject private var tokenManager = TokenManager()
    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.scenePhase) private var scenePhase

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

        NotificationPoller.shared.requestPermission()
        NotificationPoller.shared.registerBackgroundTask()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(tokenManager)
                .environmentObject(authViewModel)
                .onChange(of: scenePhase) { phase in
                    switch phase {
                    case .active:
                        NotificationPoller.shared.startForegroundPolling()
                    case .background:
                        NotificationPoller.shared.stopForegroundPolling()
                        NotificationPoller.shared.scheduleBackgroundTask()
                    default:
                        break
                    }
                }
        }
    }
}
