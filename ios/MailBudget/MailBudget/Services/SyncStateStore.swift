import Foundation

struct SyncStateStore {
    private let defaults: UserDefaults
    private let lastImportBatchKey = "lastImportBatch"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadLastImportBatch() -> ImportBatch? {
        guard let data = defaults.data(forKey: lastImportBatchKey) else {
            return nil
        }
        return try? DateCoding.decoder().decode(ImportBatch.self, from: data)
    }

    func saveLastImportBatch(_ batch: ImportBatch) {
        guard let data = try? DateCoding.encoder().encode(batch) else {
            return
        }
        defaults.set(data, forKey: lastImportBatchKey)
    }

    func clear() {
        defaults.removeObject(forKey: lastImportBatchKey)
    }
}
