import Foundation

enum TransactionSourceKind: String, Codable, CaseIterable, Identifiable {
    case sample
    case mailExtracted
    case importedJSON
    case manual

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sample:
            return "サンプルデータ"
        case .mailExtracted:
            return "メール抽出データ"
        case .importedJSON:
            return "JSON取込データ"
        case .manual:
            return "手入力データ"
        }
    }
}
