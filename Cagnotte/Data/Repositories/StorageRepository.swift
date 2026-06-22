import Foundation
import UIKit

@MainActor
final class StorageRepository {
    private let api: APIService

    init(api: APIService) {
        self.api = api
    }

    func uploadImage(_ image: UIImage, folder: String = "receipts") async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw APIError.unknown("Impossible de compresser l'image")
        }

        let fileName = "photo_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        let contentType = "image/jpeg"

        let signed = try await api.getSignedUploadUrl(
            folder: folder,
            fileName: fileName,
            contentType: contentType
        )

        guard let url = URL(string: signed.uploadUrl) else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        req.httpBody = data

        let (_, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status < 400 else {
            throw APIError.serverError(status, "Echec de l'upload GCS (\(status))")
        }

        return signed.publicUrl
    }
}
