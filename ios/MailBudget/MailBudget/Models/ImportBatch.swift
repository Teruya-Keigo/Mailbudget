import Foundation

struct ImportBatch: Identifiable, Codable, Equatable {
    let id: UUID
    var source: ImportSource
    var startedAt: Date
    var finishedAt: Date
    var inputFileName: String?
    var totalCount: Int
    var insertedCount: Int
    var updatedCount: Int
    var duplicateCount: Int
    var failedCount: Int
    var message: String
}
