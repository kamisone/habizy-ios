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
    let contributionAmount: Double?
}

struct JoinColocationRequest: Encodable {
    let inviteCode: String
}

struct ColocationResponse: Decodable, Identifiable {
    let id: String
    let name: String
    let contributionAmount: Double?
    let inviteCode: String?
    let currentCycle: Int?
    let createdAt: String?
    let lowBalanceThreshold: Double?
}

struct ColocationMemberResponse: Decodable, Identifiable {
    let id: String
    let role: String
    let user: UserResponse
    let joinedAt: String?
}

struct BalanceResponse: Decodable {
    let balance: Double
    let totalContributed: Double
    let totalSpent: Double
}

struct ColocationDetailResponse: Decodable {
    let colocation: ColocationResponse
    let members: [ColocationMemberResponse]
    let balance: BalanceResponse
}

struct UpdateColocationRequest: Encodable {
    let name: String?
    let contributionAmount: Double?
    let lowBalanceThreshold: Double?
}

struct AddMemberRequest: Encodable {
    let name: String
    let email: String
    let password: String?
    let colorHex: String?
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
    let totalAmount: Double
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
    let totalAmount: Double
    let user: UserResponse
    let items: [ReceiptItemResponse]
    let createdAt: String?
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
}
