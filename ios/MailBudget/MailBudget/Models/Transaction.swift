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
    var sourceKind: TransactionSourceKind
    var importedAt: Date?
    var importBatchId: UUID?

    init(
        id: UUID,
        date: Date,
        amount: Int,
        merchant: String,
        category: String,
        paymentMethod: String,
        source: String,
        sourceMessageId: String,
        isConfirmed: Bool,
        createdAt: Date,
        updatedAt: Date,
        mailReceivedAt: Date? = nil,
        snippet: String? = nil,
        sourceKind: TransactionSourceKind? = nil,
        importedAt: Date? = nil,
        importBatchId: UUID? = nil
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.merchant = merchant
        self.category = category
        self.paymentMethod = paymentMethod
        self.source = source
        self.sourceMessageId = sourceMessageId
        self.isConfirmed = isConfirmed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.mailReceivedAt = mailReceivedAt
        self.snippet = snippet
        self.sourceKind = sourceKind ?? Transaction.inferSourceKind(source: source, sourceMessageId: sourceMessageId)
        self.importedAt = importedAt
        self.importBatchId = importBatchId
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case date
        case amount
        case merchant
        case category
        case paymentMethod
        case source
        case sourceMessageId
        case isConfirmed
        case createdAt
        case updatedAt
        case mailReceivedAt
        case snippet
        case sourceKind
        case importedAt
        case importBatchId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        amount = try container.decode(Int.self, forKey: .amount)
        merchant = try container.decode(String.self, forKey: .merchant)
        category = try container.decode(String.self, forKey: .category)
        paymentMethod = try container.decode(String.self, forKey: .paymentMethod)
        source = try container.decode(String.self, forKey: .source)
        sourceMessageId = try container.decode(String.self, forKey: .sourceMessageId)
        isConfirmed = try container.decode(Bool.self, forKey: .isConfirmed)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        mailReceivedAt = try container.decodeIfPresent(Date.self, forKey: .mailReceivedAt)
        snippet = try container.decodeIfPresent(String.self, forKey: .snippet)
        sourceKind = try container.decodeIfPresent(TransactionSourceKind.self, forKey: .sourceKind)
            ?? Transaction.inferSourceKind(source: source, sourceMessageId: sourceMessageId)
        importedAt = try container.decodeIfPresent(Date.self, forKey: .importedAt)
        importBatchId = try container.decodeIfPresent(UUID.self, forKey: .importBatchId)
    }
}

extension Transaction {
    static let categories = ["食費", "コンビニ", "交通", "日用品", "娯楽", "通信", "サブスク", "医療", "学習", "その他"]

    static func inferSourceKind(source: String, sourceMessageId: String) -> TransactionSourceKind {
        if sourceMessageId.hasPrefix("sample-") {
            return .sample
        }
        if source == "iCloud Mail" {
            return .mailExtracted
        }
        return .importedJSON
    }
}
