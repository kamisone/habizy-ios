import Foundation
import Combine

@MainActor
final class TokenManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    // nil = key not set (treat as complete); false = guest pending profile completion
    @Published var profileCompleted: Bool? = nil

    private let accessTokenKey    = "access_token"
    private let refreshTokenKey   = "refresh_token"
    private let profileCompletedKey = "profile_completed"
    private let colocationIdKey   = "colocation_id"

    init() {
        self.isLoggedIn = UserDefaults.standard.string(forKey: accessTokenKey) != nil
        if let raw = UserDefaults.standard.object(forKey: profileCompletedKey) as? Bool {
            self.profileCompleted = raw
        } else {
            self.profileCompleted = nil
        }
    }

    // MARK: - Access & Refresh Tokens

    var accessToken: String? {
        UserDefaults.standard.string(forKey: accessTokenKey)
    }

    var refreshToken: String? {
        UserDefaults.standard.string(forKey: refreshTokenKey)
    }

    func saveTokens(accessToken: String, refreshToken: String) {
        UserDefaults.standard.set(accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
        self.isLoggedIn = true
    }

    func saveAuthResponse(_ response: AuthResponse) {
        saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        if let completed = response.profileCompleted {
            saveProfileCompleted(completed)
        }
    }

    func saveProfileCompleted(_ completed: Bool) {
        UserDefaults.standard.set(completed, forKey: profileCompletedKey)
        self.profileCompleted = completed
    }

    func setAccessToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: accessTokenKey)
    }

    // MARK: - Colocation ID

    var colocationId: String? {
        get { UserDefaults.standard.string(forKey: colocationIdKey) }
        set { UserDefaults.standard.set(newValue, forKey: colocationIdKey) }
    }

    func saveColocationId(_ id: String) {
        UserDefaults.standard.set(id, forKey: colocationIdKey)
    }

    // MARK: - Clear

    func clear() {
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: profileCompletedKey)
        UserDefaults.standard.removeObject(forKey: colocationIdKey)
        self.isLoggedIn = false
        self.profileCompleted = nil
    }
}
