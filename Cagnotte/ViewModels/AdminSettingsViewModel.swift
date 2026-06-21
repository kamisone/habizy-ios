import Foundation

@MainActor
final class AdminSettingsViewModel: ObservableObject {
    @Published var colocation: ColocationResponse?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var contributionAmount: String = ""
    @Published var lowBalanceThreshold: String = ""
    @Published var colocationName: String = ""

    private let colocationRepo: ColocationRepository
    private let rotationRepo: RotationRepository
    private let tokenManager: TokenManager

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.colocationRepo = ColocationRepository(api: api, tokenManager: tokenManager)
        self.rotationRepo = RotationRepository(api: api)
    }

    var colocationId: String? { tokenManager.colocationId }

    func load() {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                let detail = try await colocationRepo.getMyColocation()
                colocation = detail.colocation
                colocationName = detail.colocation.name
                if let amt = detail.colocation.contributionAmount {
                    contributionAmount = String(format: "%.2f", amt)
                }
                if let threshold = detail.colocation.lowBalanceThreshold {
                    lowBalanceThreshold = String(format: "%.2f", threshold)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func saveSettings() {
        guard let id = colocationId else { return }
        let amount = Double(contributionAmount.replacingOccurrences(of: ",", with: "."))
        let threshold = Double(lowBalanceThreshold.replacingOccurrences(of: ",", with: "."))
        Task {
            isSaving = true
            defer { isSaving = false }
            do {
                colocation = try await colocationRepo.updateColocation(
                    id: id,
                    name: colocationName.isEmpty ? nil : colocationName,
                    contributionAmount: amount,
                    lowBalanceThreshold: threshold
                )
                successMessage = "Paramètres sauvegardés"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func generateRotation() {
        guard let id = colocationId else { return }
        Task {
            isSaving = true
            defer { isSaving = false }
            do {
                _ = try await rotationRepo.generate(colocationId: id)
                successMessage = "Rotation générée !"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
