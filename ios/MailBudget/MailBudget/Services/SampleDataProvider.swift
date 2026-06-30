import Foundation

struct SampleDataProvider {
    func loadSampleTransactions(importedAt: Date = Date()) throws -> [Transaction] {
        guard let url = Bundle.main.url(forResource: "sample_transactions", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }

        let data = try Data(contentsOf: url)
        let rows = try DateCoding.decoder().decode([Transaction].self, from: data)
        return rows.map { transaction in
            var copied = transaction
            copied.sourceKind = .sample
            copied.importedAt = importedAt
            copied.importBatchId = nil
            return copied
        }
    }
}
