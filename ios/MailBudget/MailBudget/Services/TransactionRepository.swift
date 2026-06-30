import Foundation

struct TransactionRepository {
    private let fileName: String

    init(fileName: String = "transactions.json") {
        self.fileName = fileName
    }

    func exists() -> Bool {
        FileManager.default.fileExists(atPath: storageURL().path)
    }

    func loadTransactions() throws -> [Transaction] {
        let data = try Data(contentsOf: storageURL())
        return try DateCoding.decoder().decode([Transaction].self, from: data)
    }

    func saveTransactions(_ transactions: [Transaction]) throws {
        let data = try DateCoding.encoder().encode(transactions)
        try data.write(to: storageURL(), options: [.atomic])
    }

    func deleteTransactions() throws {
        let url = storageURL()
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    func lastModifiedAt() -> Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: storageURL().path)
        return attributes?[.modificationDate] as? Date
    }

    func storageURL() -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent(fileName)
    }
}
