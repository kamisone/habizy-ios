import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoginLoading = false
    @Published var isJoinLoading = false
    @Published var loginError: String?
    @Published var joinError: String?

    private var tokenManager: TokenManager?
    private var authRepo: AuthRepository?

    func setup(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.authRepo = AuthRepository(api: api, tokenManager: tokenManager)
    }

    func login(email: String, password: String) {
        guard let repo = authRepo else { return }
        isLoginLoading = true
        loginError = nil
        Task {
            defer { isLoginLoading = false }
            do {
                let resp = try await repo.login(email: email, password: password)
                // profileCompleted nil = existing user (treat as true)
                if resp.profileCompleted == nil {
                    tokenManager?.saveProfileCompleted(true)
                }
            } catch {
                loginError = error.localizedDescription
            }
        }
    }

    func joinColocation(inviteCode: String) {
        guard let repo = authRepo else { return }
        isJoinLoading = true
        joinError = nil
        Task {
            defer { isJoinLoading = false }
            do {
                _ = try await repo.joinColocation(inviteCode: inviteCode)
            } catch {
                joinError = error.localizedDescription
            }
        }
    }

    func logout() {
        authRepo?.logout()
    }

    func deleteAccountAndLogout() {
        Task {
            try? await authRepo?.deleteMe()
        }
    }
}
