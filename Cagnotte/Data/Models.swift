import Foundation

// MARK: - Auth Models

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let name: String
    let email: String
    let password: String
}

struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let profileCompleted: Bool?
}

struct UserResponse: Decodable, Identifiable {
    let id: String
    let email: String
    let name: String
    let colorHex: String?
    let initial: String?
    let phone: String?
    let isAdmin: Bool
    let profileCompleted: Bool?
}

struct CompleteProfileRequest: Encodable {
    let name: String
    let email: String
    let password: String
    let colorHex: String?
    let phone: String?
}

struct ChangePasswordRequest: Encodable {
    let currentPassword: String
    let newPassword: String
}

struct CreateUserResponse: Decodable, Equatable {
    let user: UserResponse
    let generatedPassword: String?
}

extension UserResponse: Equatable {
    static func == (lhs: UserResponse, rhs: UserResponse) -> Bool { lhs.id == rhs.id }
}

// MARK: - Colocation Models

struct CreateColocationRequest: Encodable {
    let name: String
}

struct JoinColocationRequest: Encodable {
    let inviteCode: String
}

struct ColocationResponse: Decodable, Identifiable {
    let id: String
    let name: String
    let inviteCode: String?
    let createdAt: String?
    let spendingGapThreshold: Double?
    let notificationsEnabled: Bool?
}

struct ColocationMemberResponse: Decodable, Identifiable {
    let id: String
    let role: String
    let user: UserResponse
    let joinedAt: String?
}

struct ColocationDetailResponse: Decodable {
    let colocation: ColocationResponse
    let members: [ColocationMemberResponse]
}

struct UpdateColocationRequest: Encodable {
    let name: String?
    let spendingGapThreshold: Double?
    let notificationsEnabled: Bool?
}

struct AddMemberRequest: Encodable {
    let name: String
    let email: String
    let password: String?
    let colorHex: String?
}

struct SetPurchaseOrderRequest: Encodable {
    let userIds: [String]
}

// MARK: - Contribution Models

struct CreateContributionRequest: Encodable {
    let colocationId: String
    let amount: Double?
}

struct ContributionResponse: Decodable, Identifiable {
    let id: String
    let amount: Double
    let cycleNumber: Int?
    let user: UserResponse
    let createdAt: String?
}

struct ContributionStatusItem: Decodable {
    let user: UserResponse
    let hasPaid: Bool
}

struct CycleStatusResponse: Decodable {
    let cycleNumber: Int
    let paidCount: Int
    let totalMembers: Int
    let contributions: [ContributionStatusItem]
}

// MARK: - Catalog Models

struct CatalogArticle: Decodable, Identifiable {
    let id: String
    let name: String
    let category: String
    let colocationId: String
    let createdAt: String?
}

struct CreateCatalogArticleRequest: Encodable {
    let name: String
    let category: String
    let colocationId: String
}

// MARK: - Receipt Models

struct CreateReceiptItemRequest: Encodable {
    let name: String
    let price: Double
    let quantity: Int
    let category: String
}

struct CreateReceiptRequest: Encodable {
    let colocationId: String
    let store: String
    let date: String
    let time: String?
    let totalAmount: Double
    let photoUrl: String?
    let items: [CreateReceiptItemRequest]
}

struct ReceiptItemResponse: Decodable, Identifiable {
    let id: String
    let name: String
    let price: Double
    let quantity: Int
    let category: String
}

struct ReceiptResponse: Decodable, Identifiable {
    let id: String
    let store: String
    let date: String
    let time: String?
    let totalAmount: Double
    let photoUrl: String?
    let user: UserResponse
    let items: [ReceiptItemResponse]
    let createdAt: String?
}

struct ArticleSuggestion: Decodable, Identifiable {
    var id: String { name }
    let name: String
    let category: String
    let lastPrice: Double
}

struct ArticleStat: Decodable, Identifiable {
    var id: String { name }
    let name: String
    let category: String
    let totalAmount: Double
    let totalQuantity: Int
    let fraction: Double
}

struct CategoryStat: Decodable, Identifiable {
    var id: String { category }
    let category: String
    let total: Double
    let fraction: Double
}

struct RoommateStat: Decodable, Identifiable {
    var id: String { user?.id ?? UUID().uuidString }
    let user: UserResponse?
    let total: Double
    let fraction: Double
}

struct ExpenseStatsResponse: Decodable {
    let totalSpent: Double
    let byCategory: [CategoryStat]
    let byRoommate: [RoommateStat]
}

// MARK: - Shopping Models

struct CreateShoppingItemRequest: Encodable {
    let name: String
    let quantity: Int
    let assigneeId: String?
    let colocationId: String
}

struct ShoppingItemResponse: Decodable, Identifiable {
    let id: String
    let name: String
    let quantity: Int
    let isChecked: Bool
    let assignee: UserResponse?
    let checkedBy: UserResponse?
    let createdAt: String?
}

// MARK: - Notification Models

struct NotificationResponse: Decodable, Identifiable {
    let id: String
    let type: String
    let message: String
    let isRead: Bool
    let actor: UserResponse?
    let createdAt: String?
}

// MARK: - Storage Models

struct SignedUploadUrlRequest: Encodable {
    let folder: String
    let fileName: String
    let contentType: String
}

struct SignedUploadUrlResponse: Decodable {
    let uploadUrl: String
    let publicUrl: String
    let key: String
}

// MARK: - Rotation Models

struct SwapRotationRequest: Encodable {
    let myRotationId: String
    let theirRotationId: String
}

struct RotationEntryResponse: Decodable, Identifiable {
    let id: String
    let user: UserResponse
    let weekStart: String?
    let weekEnd: String?
    let orderIndex: Int
    let status: String?
    let isDisabled: Bool?
}

// MARK: - Report Models

struct ReportResponse: Decodable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let tags: [String]?
    let photoUrls: [String]?
    let user: UserResponse
    let colocationId: String
    let commentCount: Int?
    let createdAt: String?
    let updatedAt: String?
}

struct ReportCommentResponse: Decodable, Identifiable {
    let id: String
    let content: String
    let user: UserResponse
    let createdAt: String?
}

struct ReportDetailResponse: Decodable {
    let id: String
    let title: String
    let description: String?
    let tags: [String]?
    let photoUrls: [String]?
    let user: UserResponse
    let colocationId: String
    let comments: [ReportCommentResponse]
    let createdAt: String?
    let updatedAt: String?
}

struct CreateReportRequest: Encodable {
    let colocationId: String
    let title: String
    let description: String?
    let tags: [String]?
    let photoUrls: [String]?
}

struct UpdateReportRequest: Encodable {
    let title: String?
    let description: String?
    let tags: [String]?
    let photoUrls: [String]?
}

struct CreateReportCommentRequest: Encodable {
    let content: String
}

struct ReportTagResponse: Decodable, Identifiable {
    let id: String
    let title: String
    let color: String
    let colocationId: String
}

struct CreateTagRequest: Encodable {
    let title: String
    let color: String
    let colocationId: String
}

// MARK: - Ménage

struct MenageBoardMember: Decodable {
    let userId: String
    let name: String
    let initial: String?
    let colorHex: String?
    let done: Bool
    let doneAt: String?
    let comment: String?
}

struct MarkMenageDoneRequest: Encodable {
    let comment: String?
}

struct MenageWeekResponse: Decodable {
    let weekStart: String
    let board: [MenageBoardMember]
    let totalMembers: Int
    let totalDone: Int
    let todayTakenBy: String?
}
