import Foundation

// MARK: - API Error
enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(String)
    case serverError(Int, String)
    case unauthorized
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:            return "URL invalide"
        case .noData:                return "Aucune donnée reçue"
        case .decodingError(let m):  return "Erreur de décodage: \(m)"
        case .serverError(_, let m): return m
        case .unauthorized:          return "Session expirée, veuillez vous reconnecter"
        case .unknown(let m):        return m
        }
    }
}

// MARK: - Base URL Helper
private func baseURL() -> String {
#if DEBUG
    return "http://localhost:4000/"
#else
    return "https://silomis.com/api/"
#endif
}

// MARK: - APIService
@MainActor
final class APIService {
    static let shared = APIService()
    private let tokenManager: TokenManager

    init() {
        // Will be replaced by injected token manager via setup
        self.tokenManager = TokenManager()
    }

    private var _tokenManager: TokenManager?

    static func configure(tokenManager: TokenManager) -> APIService {
        let svc = APIService.shared
        svc._tokenManager = tokenManager
        return svc
    }

    private var tm: TokenManager {
        _tokenManager ?? tokenManager
    }

    // MARK: - Core Request
    private func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        auth: Bool = true,
        retryOnUnauthorized: Bool = true
    ) async throws -> T {
        guard let url = URL(string: baseURL() + path) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if auth, let token = tm.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: req)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        if statusCode == 401 && retryOnUnauthorized && auth {
            // Try refresh
            let refreshed = try? await refreshTokens()
            if refreshed == true {
                return try await request(path, method: method, body: body, auth: auth, retryOnUnauthorized: false)
            } else {
                tm.clear()
                throw APIError.unauthorized
            }
        }

        if statusCode >= 400 {
            let msg = extractErrorMessage(data: data) ?? "Erreur \(statusCode)"
            throw APIError.serverError(statusCode, msg)
        }

        if data.isEmpty {
            // For Void responses
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    private func requestVoid(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        auth: Bool = true,
        retryOnUnauthorized: Bool = true
    ) async throws {
        guard let url = URL(string: baseURL() + path) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if auth, let token = tm.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: req)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        if statusCode == 401 && retryOnUnauthorized && auth {
            let refreshed = try? await refreshTokens()
            if refreshed == true {
                try await requestVoid(path, method: method, body: body, auth: auth, retryOnUnauthorized: false)
                return
            } else {
                tm.clear()
                throw APIError.unauthorized
            }
        }

        if statusCode >= 400 {
            let msg = extractErrorMessage(data: data) ?? "Erreur \(statusCode)"
            throw APIError.serverError(statusCode, msg)
        }
    }

    private func refreshTokens() async throws -> Bool {
        guard let refresh = tm.refreshToken else { return false }
        guard let url = URL(string: baseURL() + "auth/refresh") else { return false }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(RefreshTokenRequest(refreshToken: refresh))

        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status < 400 else { return false }

        let authResp = try JSONDecoder().decode(AuthResponse.self, from: data)
        tm.saveTokens(accessToken: authResp.accessToken, refreshToken: authResp.refreshToken)
        return true
    }

    private func extractErrorMessage(data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let msg = json["message"] as? String { return msg }
            if let msgs = json["message"] as? [String] { return msgs.first }
        }
        return nil
    }

    // MARK: - Auth Endpoints

    func register(body: RegisterRequest) async throws -> CreateUserResponse {
        try await request("auth/register", method: "POST", body: body, auth: false)
    }

    func login(body: LoginRequest) async throws -> AuthResponse {
        try await request("auth/login", method: "POST", body: body, auth: false)
    }

    func changePassword(body: ChangePasswordRequest) async throws {
        try await requestVoid("auth/change-password", method: "POST", body: body)
    }

    func updateName(name: String) async throws -> UserResponse {
        struct Body: Encodable { let name: String }
        return try await request("auth/me", method: "PATCH", body: Body(name: name))
    }

    func getMe() async throws -> UserResponse {
        try await request("auth/me")
    }

    func deleteMe() async throws {
        try await requestVoid("auth/me", method: "DELETE")
    }

    func completeProfile(body: CompleteProfileRequest) async throws -> AuthResponse {
        try await request("auth/profile", method: "PATCH", body: body)
    }

    // MARK: - Colocation Endpoints

    func createColocation(body: CreateColocationRequest) async throws -> ColocationResponse {
        try await request("colocations", method: "POST", body: body)
    }

    func getMyColocation() async throws -> ColocationDetailResponse {
        try await request("colocations/mine")
    }

    func joinColocation(body: JoinColocationRequest) async throws -> AuthResponse {
        try await request("colocations/join", method: "POST", body: body, auth: false)
    }

    func updateColocation(id: String, body: UpdateColocationRequest) async throws -> ColocationResponse {
        try await request("colocations/\(id)", method: "PATCH", body: body)
    }

    func addMember(colocationId: String, body: AddMemberRequest) async throws -> CreateUserResponse {
        try await request("colocations/\(colocationId)/members", method: "POST", body: body)
    }

    func removeMember(colocationId: String, userId: String) async throws {
        try await requestVoid("colocations/\(colocationId)/members/\(userId)", method: "DELETE")
    }

    func setPurchaseOrder(colocationId: String, userIds: [String]) async throws -> ColocationResponse {
        try await request("colocations/\(colocationId)/purchase-order", method: "PUT", body: SetPurchaseOrderRequest(userIds: userIds))
    }

    func toggleMemberActive(colocationId: String, userId: String) async throws {
        try await requestVoid("colocations/\(colocationId)/members/\(userId)/toggle-active", method: "PATCH")
    }

    // MARK: - Shopping Endpoints

    func getShoppingList(colocationId: String) async throws -> [ShoppingItemResponse] {
        try await request("shopping/\(colocationId)")
    }

    func createShoppingItem(body: CreateShoppingItemRequest) async throws -> ShoppingItemResponse {
        try await request("shopping", method: "POST", body: body)
    }

    func toggleShoppingItem(id: String) async throws -> ShoppingItemResponse {
        try await request("shopping/\(id)/toggle", method: "PATCH")
    }

    func deleteShoppingItem(id: String) async throws {
        try await requestVoid("shopping/\(id)", method: "DELETE")
    }

    // MARK: - Storage Endpoints

    func getSignedUploadUrl(folder: String, fileName: String, contentType: String) async throws -> SignedUploadUrlResponse {
        let body = SignedUploadUrlRequest(folder: folder, fileName: fileName, contentType: contentType)
        return try await request("storage/signed-upload-url", method: "POST", body: body)
    }

    // MARK: - Receipt Endpoints

    func createReceipt(body: CreateReceiptRequest) async throws -> ReceiptResponse {
        try await request("receipts", method: "POST", body: body)
    }

    func getReceipts(colocationId: String) async throws -> [ReceiptResponse] {
        try await request("receipts/\(colocationId)")
    }

    func getExpenseStats(colocationId: String) async throws -> ExpenseStatsResponse {
        try await request("receipts/\(colocationId)/stats")
    }

    func deleteReceipt(id: String) async throws {
        try await requestVoid("receipts/\(id)", method: "DELETE")
    }

    func getArticleCatalog(colocationId: String) async throws -> [ArticleSuggestion] {
        try await request("receipts/\(colocationId)/articles")
    }

    func getArticleStats(colocationId: String) async throws -> [ArticleStat] {
        try await request("receipts/\(colocationId)/articles/stats")
    }

    // MARK: - Catalog Endpoints

    func getCatalogArticles(colocationId: String) async throws -> [CatalogArticle] {
        try await request("catalog/\(colocationId)")
    }

    func getCatalogCategories(colocationId: String) async throws -> [String] {
        try await request("catalog/\(colocationId)/categories")
    }

    func createCatalogArticle(body: CreateCatalogArticleRequest) async throws -> CatalogArticle {
        try await request("catalog", method: "POST", body: body)
    }

    func deleteCatalogArticle(id: String) async throws {
        try await requestVoid("catalog/\(id)", method: "DELETE")
    }

    // MARK: - Rotation Endpoints

    func getRotation(colocationId: String) async throws -> [RotationEntryResponse] {
        try await request("rotations/\(colocationId)")
    }

    func generateRotation(colocationId: String) async throws -> [RotationEntryResponse] {
        try await request("rotations/\(colocationId)/generate", method: "POST")
    }

    func swapRotation(body: SwapRotationRequest) async throws -> [RotationEntryResponse] {
        try await request("rotations/swap", method: "PATCH", body: body)
    }

    // MARK: - Notification Endpoints

    func getNotifications() async throws -> [NotificationResponse] {
        try await request("notifications")
    }

    func markNotificationRead(id: String) async throws {
        try await requestVoid("notifications/\(id)/read", method: "PATCH")
    }

    // MARK: - Report Endpoints

    func getReports(colocationId: String, tag: String? = nil) async throws -> [ReportResponse] {
        var path = "reports/\(colocationId)"
        if let tag { path += "?tag=\(tag)" }
        return try await request(path)
    }

    func createReport(body: CreateReportRequest) async throws -> ReportResponse {
        try await request("reports", method: "POST", body: body)
    }

    func getReportDetail(id: String) async throws -> ReportDetailResponse {
        try await request("reports/\(id)/detail")
    }

    func createReportComment(id: String, content: String) async throws -> ReportCommentResponse {
        try await request("reports/\(id)/comments", method: "POST", body: CreateReportCommentRequest(content: content))
    }

    func updateReport(id: String, body: UpdateReportRequest) async throws -> ReportDetailResponse {
        try await request("reports/\(id)", method: "PATCH", body: body)
    }

    func deleteReport(id: String) async throws {
        try await requestVoid("reports/\(id)", method: "DELETE")
    }

    func getReportTags(colocationId: String) async throws -> [ReportTagResponse] {
        try await request("reports/tags/\(colocationId)")
    }

    func createReportTag(body: CreateTagRequest) async throws -> ReportTagResponse {
        try await request("reports/tags", method: "POST", body: body)
    }

    func deleteReportTag(id: String) async throws {
        try await requestVoid("reports/tags/\(id)", method: "DELETE")
    }
}

// Sentinel type for void responses
struct EmptyResponse: Decodable {}
