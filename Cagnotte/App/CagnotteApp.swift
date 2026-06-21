import SwiftUI

@main
struct CagnotteApp: App {
    @StateObject private var tokenManager = TokenManager()
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(tokenManager)
                .environmentObject(authViewModel)
        }
    }
}
