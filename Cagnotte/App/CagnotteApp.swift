import SwiftUI

@main
struct CagnotteApp: App {
    @StateObject private var tokenManager = TokenManager()
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        let bg = UIColor(red: 0xFB/255, green: 0xF7/255, blue: 0xF0/255, alpha: 1) // screenBackground
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
