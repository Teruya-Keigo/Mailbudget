import Foundation

struct TransactionImportService {
    struct ImportResult {
        var transactions: [Transaction]
        var batch: ImportBatch
    }

    enum ImportError: LocalizedError {
        case invalidRoot

        var errorDescription: String? {
            switch self {
            case .invalidRoot:
                return "JSONのルートは明細配列である必要があります。"
            }
        }
    }

    func importTransactions(from data: Data, fileName: String?, into existing: [Transaction]) throws -> ImportResult {
        let object = try JSONSerialization.jsonObject(with: data)
        guard object is [Any] else {
            throw ImportError.invalidRoot
        }

        let decoded = try DateCoding.decoder().decode([Transaction].self, from: data)
        let batchID = UUID()
        let startedAt = Date()
        var rows = existing
        var seenMessageIDs = Set(existing.map(\.sourceMessageId).filter { !$0.isEmpty })
        var seenPaymentKeys = Set(existing.map { paymentDuplicateKey(for: $0) })
        var seenMailKeys = Set(existing.compactMap { mailDuplicateKey(for: $0) })
        var insertedCount = 0
        var duplicateCount = 0

        for item in decoded {
            var transaction = item
            transaction.sourceKind = normalizedSourceKind(for: item)
            transaction.importedAt = startedAt
            transaction.importBatchId = batchID

            if isDuplicate(transaction, seenMessageIDs: seenMessageIDs, seenPaymentKeys: seenPaymentKeys, seenMailKeys: seenMailKeys) {
                duplicateCount += 1
                continue
            }

            rows.append(transaction)
            insertedCount += 1
            if !transaction.sourceMessageId.isEmpty {
                seenMessageIDs.insert(transaction.sourceMessageId)
            }
            seenPaymentKeys.insert(paymentDuplicateKey(for: transaction))
            if let key = mailDuplicateKey(for: transaction) {
                seenMailKeys.insert(key)
            }
        }

        let finishedAt = Date()
        let batch = ImportBatch(
            id: batchID,
            source: inferredImportSource(for: decoded),
            startedAt: startedAt,
            finishedAt: finishedAt,
            inputFileName: fileName,
            totalCount: decoded.count,
            insertedCount: insertedCount,
            updatedCount: 0,
            duplicateCount: duplicateCount,
            failedCount: 0,
            message: "読み込み \(decoded.count) 件 / 新規 \(insertedCount) 件 / 重複 \(duplicateCount) 件 / 失敗 0 件"
        )

        return ImportResult(transactions: rows, batch: batch)
    }

    private func normalizedSourceKind(for transaction: Transaction) -> TransactionSourceKind {
        if transaction.sourceMessageId.hasPrefix("sample-") {
            return .sample
        }
        if transaction.source == "iCloud Mail" {
            return .mailExtracted
        }
        if transaction.sourceKind == .manual {
            return .manual
        }
        return .importedJSON
    }

    private func inferredImportSource(for transactions: [Transaction]) -> ImportSource {
        if transactions.allSatisfy({ $0.source == "iCloud Mail" }) {
            return .mailExtractor
        }
        return .fileImporter
    }

    private func isDuplicate(
        _ transaction: Transaction,
        seenMessageIDs: Set<String>,
        seenPaymentKeys: Set<String>,
        seenMailKeys: Set<String>
    ) -> Bool {
        if !transaction.sourceMessageId.isEmpty, seenMessageIDs.contains(transaction.sourceMessageId) {
            return true
        }
        if seenPaymentKeys.contains(paymentDuplicateKey(for: transaction)) {
            return true
        }
        if let mailKey = mailDuplicateKey(for: transaction), seenMailKeys.contains(mailKey) {
            return true
        }
        return false
    }

    private func paymentDuplicateKey(for transaction: Transaction) -> String {
        [
            transaction.paymentMethod,
            DateCoding.isoDate.string(from: transaction.date),
            String(transaction.amount),
            transaction.merchant
        ].joined(separator: "|")
    }

    private func mailDuplicateKey(for transaction: Transaction) -> String? {
        guard let mailReceivedAt = transaction.mailReceivedAt else {
            return nil
        }
        return [
            ISO8601DateFormatter().string(from: mailReceivedAt),
            String(transaction.amount),
            transaction.merchant
        ].joined(separator: "|")
    }
}
