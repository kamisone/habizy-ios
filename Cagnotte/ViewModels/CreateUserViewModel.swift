import Foundation
import SwiftUI

@MainActor
final class CreateUserViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var selectedColorHex = Color.presetHexColors[0]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var createdUser: CreateUserResponse?

    private let colocationRepo: ColocationRepository
    private let tokenManager: TokenManager

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.colocationRepo = ColocationRepository(api: api, tokenManager: tokenManager)
    }

    var colocationId: String? { tokenManager.colocationId }

    func createUser() {
        guard let id = colocationId else { return }
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                let pwd = password.isEmpty ? nil : password
                let result = try await colocationRepo.addMember(
                    colocationId: id,
                    name: name,
                    email: email,
                    password: pwd,
                    colorHex: selectedColorHex
                )
                createdUser = result
                name = ""
                email = ""
                password = ""
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    var canSubmit: Bool {
        !name.isEmpty && !email.isEmpty
    }
}
