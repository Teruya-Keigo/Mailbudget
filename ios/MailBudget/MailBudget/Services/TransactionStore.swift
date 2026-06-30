import Foundation
import SwiftUI

@MainActor
final class TransactionStore: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var dataStatus: DataStatus = .empty
    @Published private(set) var lastImportBatch: ImportBatch?
    @Published var lastSyncMessage = "明細データはまだありません"
    @Published var mailSource = MailSource()

    private let repository: TransactionRepository
    private let sampleDataProvider: SampleDataProvider
    private let importService: TransactionImportService
    private let syncStateStore: SyncStateStore

    init(
        repository: TransactionRepository = TransactionRepository(),
        sampleDataProvider: SampleDataProvider = SampleDataProvider(),
        importService: TransactionImportService = TransactionImportService(),
        syncStateStore: SyncStateStore = SyncStateStore()
    ) {
        self.repository = repository
        self.sampleDataProvider = sampleDataProvider
        self.importService = importService
        self.syncStateStore = syncStateStore
        lastImportBatch = syncStateStore.loadLastImportBatch()
        load()
    }

    var isShowingSample: Bool {
        dataStatus.isSample
    }

    var sourceKindCounts: [(kind: TransactionSourceKind, count: Int)] {
        TransactionSourceKind.allCases.compactMap { kind in
            let count = transactions.filter { $0.sourceKind == kind }.count
            return count > 0 ? (kind, count) : nil
        }
    }

    var hasSavedSampleOnlyWarning: Bool {
        guard case .loadedFromDocuments = dataStatus else {
            return false
        }
        return isBundledSampleSet(transactions)
    }

    var totalThisMonth: Int {
        let calendar = Calendar.current
        return transactions
            .filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    func categoryTotals(for month: Date = Date()) -> [(category: String, total: Int)] {
        let calendar = Calendar.current
        let totals = transactions
            .filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
            .reduce(into: [String: Int]()) { result, transaction in
                result[transaction.category, default: 0] += transaction.amount
            }
        return totals.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }

    func paymentMethodTotals(for month: Date = Date()) -> [(paymentMethod: String, total: Int)] {
        let calendar = Calendar.current
        let totals = transactions
            .filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
            .reduce(into: [String: Int]()) { result, transaction in
                result[transaction.paymentMethod, default: 0] += transaction.amount
            }
        return totals.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }

    func monthlyTotals() -> [(month: String, total: Int)] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        let totals = transactions.reduce(into: [String: Int]()) { result, transaction in
            result[formatter.string(from: transaction.date), default: 0] += transaction.amount
        }
        return totals.sorted { $0.key > $1.key }.map { ($0.key, $0.value) }
    }

    func upsert(_ transaction: Transaction) {
        var updated = transaction
        updated.updatedAt = Date()
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = updated
        } else {
            transactions.append(updated)
        }
        if dataStatus.isSample {
            sortTransactions()
            lastSyncMessage = "サンプル表示中の変更は保存されません"
            return
        }
        sortAndSave()
    }

    func delete(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
        if dataStatus.isSample {
            lastSyncMessage = "サンプル表示中の変更は保存されません"
            return
        }
        if save() {
            refreshLoadedStatus(message: "明細を削除しました")
        }
    }

    func deleteAll() {
        transactions.removeAll()
        do {
            try repository.deleteTransactions()
            syncStateStore.clear()
            lastImportBatch = nil
            dataStatus = .empty
            lastSyncMessage = "保存済みデータを削除しました"
        } catch {
            dataStatus = .error(message: "保存済みデータを削除できませんでした")
            lastSyncMessage = "保存済みデータを削除できませんでした"
        }
    }

    func showSampleData() {
        do {
            transactions = try sampleDataProvider.loadSampleTransactions()
            sortTransactions()
            dataStatus = .sample(count: transactions.count)
            lastSyncMessage = "サンプルデータを \(transactions.count) 件表示中です"
        } catch {
            dataStatus = .error(message: "サンプルデータを読み込めませんでした")
            lastSyncMessage = "サンプルJSONを読み込めませんでした"
        }
    }

    func clearSampleData() {
        load()
    }

    func importJSON(from url: URL) {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            let baseRows = try rowsForImportBase()
            let result = try importService.importTransactions(
                from: data,
                fileName: url.lastPathComponent,
                into: baseRows
            )

            transactions = result.transactions.sorted { $0.date > $1.date }
            let rowsToSave = transactions.filter { $0.sourceKind != .sample }
            try repository.saveTransactions(rowsToSave)
            lastImportBatch = result.batch
            syncStateStore.saveLastImportBatch(result.batch)
            dataStatus = .imported(count: transactions.count, importedAt: result.batch.finishedAt)
            lastSyncMessage = result.batch.message
        } catch {
            dataStatus = .error(message: "JSONを読み込めませんでした")
            lastSyncMessage = "JSONを読み込めませんでした。既存の明細データは変更されていません。"
        }
    }

    func importBundledSample() {
        showSampleData()
    }

    func exportJSON() -> URL? {
        if dataStatus.isSample {
            return writeTemporaryJSON(named: "sample_transactions_export.json", rows: transactions)
        }
        guard save() else {
            return nil
        }
        return repository.storageURL()
    }

    func exportCSV() -> URL? {
        let url = temporaryURL(named: "transactions.csv")
        let header = "date,amount,merchant,category,paymentMethod,sourceKind,sourceMessageId,isConfirmed\n"
        let body = transactions.map { transaction in
            [
                DateCoding.isoDate.string(from: transaction.date),
                String(transaction.amount),
                csv(transaction.merchant),
                csv(transaction.category),
                csv(transaction.paymentMethod),
                csv(transaction.sourceKind.rawValue),
                csv(transaction.sourceMessageId),
                String(transaction.isConfirmed)
            ].joined(separator: ",")
        }.joined(separator: "\n")
        do {
            try (header + body + "\n").write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            lastSyncMessage = "CSV出力に失敗しました"
            return nil
        }
    }

    private func load() {
        do {
            guard repository.exists() else {
                transactions = []
                dataStatus = .empty
                lastSyncMessage = "明細データはまだありません"
                return
            }

            transactions = try repository.loadTransactions().sorted { $0.date > $1.date }
            if transactions.isEmpty {
                dataStatus = .empty
                lastSyncMessage = "明細データはまだありません"
            } else {
                dataStatus = .loadedFromDocuments(
                    count: transactions.count,
                    updatedAt: repository.lastModifiedAt()
                )
                if hasSavedSampleOnlyWarning {
                    lastSyncMessage = "現在保存されているデータはサンプルデータの可能性があります"
                } else {
                    lastSyncMessage = "保存済みデータを \(transactions.count) 件読み込みました"
                }
            }
        } catch {
            transactions = []
            dataStatus = .error(message: "保存済みデータを読み込めませんでした")
            lastSyncMessage = "保存済みデータを読み込めませんでした"
        }
    }

    private func sortAndSave() {
        sortTransactions()
        if save() {
            refreshLoadedStatus(message: "保存しました")
        }
    }

    private func sortTransactions() {
        transactions.sort { $0.date > $1.date }
    }

    private func save() -> Bool {
        do {
            try repository.saveTransactions(transactions)
            return true
        } catch {
            lastSyncMessage = "保存に失敗しました"
            dataStatus = .error(message: "保存に失敗しました")
            return false
        }
    }

    private func refreshLoadedStatus(message: String) {
        if transactions.isEmpty {
            dataStatus = .empty
            lastSyncMessage = "明細データはまだありません"
        } else {
            dataStatus = .loadedFromDocuments(count: transactions.count, updatedAt: repository.lastModifiedAt())
            lastSyncMessage = message
        }
    }

    private func rowsForImportBase() throws -> [Transaction] {
        if dataStatus.isSample {
            guard repository.exists() else {
                return []
            }
            return try repository.loadTransactions()
        }
        return transactions.filter { $0.sourceKind != .sample }
    }

    private func isBundledSampleSet(_ rows: [Transaction]) -> Bool {
        let sampleIDs = Set(["sample-001", "sample-002", "sample-003", "sample-004", "sample-005"])
        return rows.count == sampleIDs.count && Set(rows.map(\.sourceMessageId)) == sampleIDs
    }

    private func writeTemporaryJSON(named name: String, rows: [Transaction]) -> URL? {
        let url = temporaryURL(named: name)
        do {
            let data = try DateCoding.encoder().encode(rows)
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            lastSyncMessage = "JSON出力に失敗しました"
            return nil
        }
    }

    private func temporaryURL(named name: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(name)
    }

    private func csv(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
