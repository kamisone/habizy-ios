import SwiftUI

struct RootView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var splashVisible = true
    @State private var splashOpacity: Double = 1

    var body: some View {
        ZStack {
            Color.screenBackground.ignoresSafeArea()

            if !tokenManager.isLoggedIn {
                NavigationStack {
                    WelcomeView()
                        .navigationDestination(for: AuthRoute.self) { route in
                            switch route {
                            case .login:    LoginView()
                            case .register: RegisterView()
                            case .join:     JoinView()
                            }
                        }
                }
            } else if tokenManager.profileCompleted == false {
                CompleteProfileView()
            } else {
                MainTabView()
            }

            if splashVisible {
                SplashView()
                    .opacity(splashOpacity)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            authViewModel.setup(tokenManager: tokenManager)
            guard splashVisible else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.4)) {
                    splashOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    splashVisible = false
                }
            }
        }
    }
}
