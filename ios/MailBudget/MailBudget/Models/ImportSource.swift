import Foundation

enum ImportSource: String, Codable, CaseIterable {
    case bundledSample
    case documentsJSON
    case fileImporter
    case mailExtractor
    case manual

    var displayName: String {
        switch self {
        case .bundledSample:
            return "バンドル済みサンプル"
        case .documentsJSON:
            return "Documents JSON"
        case .fileImporter:
            return "ファイル取込"
        case .mailExtractor:
            return "メール抽出結果"
        case .manual:
            return "手入力"
        }
    }
}
