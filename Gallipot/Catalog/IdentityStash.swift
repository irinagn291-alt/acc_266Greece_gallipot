import Foundation

/// Local cache of resolved tin identities so lookup still works offline.
actor IdentityStash {
    private var map: [String: TinIdentity]
    private let url: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(url: URL) {
        self.url = url
        decoder.keyDecodingStrategy = .useDefaultKeys
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path),
           let data = try? Data(contentsOf: url),
           let decoded = try? decoder.decode([String: TinIdentity].self, from: data) {
            map = decoded
        } else {
            map = [:]
        }
    }

    func remember(_ identity: TinIdentity) {
        map[identity.barcode] = identity
        persist()
    }

    func recall(_ barcode: String) -> TinIdentity? {
        map[barcode]
    }

    func reset() {
        map = [:]
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
            } catch {
                map = [:]
            }
        }
    }

    private func persist() {
        let fileManager = FileManager.default
        do {
            let folder = url.deletingLastPathComponent()
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            let data = try encoder.encode(map)
            try data.write(to: url, options: .atomic)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var mutable = url
            try mutable.setResourceValues(values)
        } catch {
            // In-memory stash remains the working catalogue if the file write fails.
        }
    }
}
