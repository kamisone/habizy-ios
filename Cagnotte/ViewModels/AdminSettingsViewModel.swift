import Foundation

@MainActor
final class AdminSettingsViewModel: ObservableObject {
    @Published var colocation: ColocationResponse?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var spendingGapThreshold: String = ""
    @Published var colocationName: String = ""
    @Published var notificationsEnabled: Bool = true

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
                if let threshold = detail.colocation.spendingGapThreshold {
                    spendingGapThreshold = String(format: "%.0f", threshold)
                }
                notificationsEnabled = detail.colocation.notificationsEnabled ?? true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func saveSettings() {
        guard let id = colocationId else { return }
        let threshold = Double(spendingGapThreshold.replacingOccurrences(of: ",", with: "."))
        Task {
            isSaving = true
            defer { isSaving = false }
            do {
                colocation = try await colocationRepo.updateColocation(
                    id: id,
                    name: colocationName.isEmpty ? nil : colocationName,
                    spendingGapThreshold: threshold,
                    notificationsEnabled: notificationsEnabled
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
