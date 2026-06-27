import Foundation

@MainActor
final class AuthRepository {
    private let api: APIService
    private let tokenManager: TokenManager

    init(api: APIService, tokenManager: TokenManager) {
        self.api = api
        self.tokenManager = tokenManager
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let response = try await api.login(body: LoginRequest(email: email, password: password))
        tokenManager.saveAuthResponse(response)
        return response
    }

    func registerAdmin(name: String, email: String, password: String) async throws {
        _ = try await api.registerAdmin(body: RegisterRequest(name: name, email: email, password: password))
        let loginResponse = try await api.login(body: LoginRequest(email: email, password: password))
        tokenManager.saveAuthResponse(loginResponse)
        if loginResponse.profileCompleted == nil {
            tokenManager.saveProfileCompleted(true)
        }
    }

    func joinColocation(inviteCode: String) async throws -> AuthResponse {
        let response = try await api.joinColocation(body: JoinColocationRequest(inviteCode: inviteCode))
        tokenManager.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        if let completed = response.profileCompleted {
            tokenManager.saveProfileCompleted(completed)
        } else {
            tokenManager.saveProfileCompleted(false)
        }
        return response
    }

    func completeProfile(name: String, email: String, password: String, colorHex: String?, phone: String?) async throws -> AuthResponse {
        let body = CompleteProfileRequest(name: name, email: email, password: password, colorHex: colorHex, phone: phone)
        let response = try await api.completeProfile(body: body)
        tokenManager.saveAuthResponse(response)
        tokenManager.saveProfileCompleted(true)
        return response
    }

    func getMe() async throws -> UserResponse {
        try await api.getMe()
    }

    func changePassword(current: String, new: String) async throws {
        try await api.changePassword(body: ChangePasswordRequest(currentPassword: current, newPassword: new))
    }

    func updateName(_ name: String) async throws -> UserResponse {
        try await api.updateName(name: name)
    }

    func deleteMe() async throws {
        try await api.deleteMe()
        tokenManager.clear()
    }

    func logout() {
        tokenManager.clear()
    }
}
