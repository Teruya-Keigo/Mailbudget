import Foundation

struct Transaction: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var date: Date
    var amount: Int
    var merchant: String
    var category: String
    var paymentMethod: String
    var source: String
    var sourceMessageId: String
    var isConfirmed: Bool
    var createdAt: Date
    var updatedAt: Date
    var mailReceivedAt: Date?
    var snippet: String?
}

extension Transaction {
    static let categories = ["食費", "コンビニ", "交通", "日用品", "娯楽", "通信", "サブスク", "医療", "学習", "その他"]
}
