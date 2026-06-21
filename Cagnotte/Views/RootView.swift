import SwiftUI

struct RootView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if !tokenManager.isLoggedIn {
                LoginView()
            } else if tokenManager.profileCompleted == false {
                CompleteProfileView()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            authViewModel.setup(tokenManager: tokenManager)
        }
    }
}
