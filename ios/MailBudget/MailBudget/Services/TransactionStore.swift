import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class TransactionStore: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    @Published var lastSyncMessage = "未同期"
    @Published var mailSource = MailSource()

    private let fileName = "transactions.json"

    init() {
        load()
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
        sortAndSave()
    }

    func delete(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
        save()
    }

    func deleteAll() {
        transactions.removeAll()
        save()
    }

    func importBundledSample() {
        guard let url = Bundle.main.url(forResource: "sample_transactions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rows = try? DateCoding.decoder().decode([Transaction].self, from: data)
        else {
            lastSyncMessage = "サンプルJSONを読み込めませんでした"
            return
        }
        transactions = rows
        sortAndSave()
        lastSyncMessage = "サンプルを \(rows.count) 件読み込みました"
    }

    func exportJSON() -> URL? {
        save()
        return storageURL()
    }

    func exportCSV() -> URL? {
        let url = temporaryURL(named: "transactions.csv")
        let header = "date,amount,merchant,category,paymentMethod,sourceMessageId,isConfirmed\n"
        let body = transactions.map { transaction in
            [
                DateCoding.isoDate.string(from: transaction.date),
                String(transaction.amount),
                csv(transaction.merchant),
                csv(transaction.category),
                csv(transaction.paymentMethod),
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
        let url = storageURL()
        if FileManager.default.fileExists(atPath: url.path),
           let data = try? Data(contentsOf: url),
           let rows = try? DateCoding.decoder().decode([Transaction].self, from: data) {
            transactions = rows
            return
        }
        importBundledSample()
    }

    private func sortAndSave() {
        transactions.sort { $0.date > $1.date }
        save()
    }

    private func save() {
        do {
            let data = try DateCoding.encoder().encode(transactions)
            try data.write(to: storageURL(), options: [.atomic])
        } catch {
            lastSyncMessage = "保存に失敗しました"
        }
    }

    private func storageURL() -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent(fileName)
    }

    private func temporaryURL(named name: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(name)
    }

    private func csv(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
