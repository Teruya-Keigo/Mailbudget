import Foundation

enum DataStatus: Equatable {
    case empty
    case loadedFromDocuments(count: Int, updatedAt: Date?)
    case sample(count: Int)
    case imported(count: Int, importedAt: Date)
    case error(message: String)

    var isSample: Bool {
        if case .sample = self {
            return true
        }
        return false
    }
}
