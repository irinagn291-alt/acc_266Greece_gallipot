import Foundation

/// UserDefaults projection of the stillroom. In-memory StillroomStore remains the source of truth.
actor StillroomVault {
    static let stillroomKey = "glp.stillroom.v1"
    static let demoKey = "glp.demo.v1"

    private let suiteName: String?
    private let backupURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(suiteName: String? = nil, backupURL: URL) {
        self.suiteName = suiteName
        self.backupURL = backupURL
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder
    }

    private var defaults: UserDefaults {
        if let suiteName {
            return UserDefaults(suiteName: suiteName) ?? .standard
        }
        return .standard
    }

    private var fileManager: FileManager { .default }

    func load() -> StillroomDocument {
        if let data = defaults.data(forKey: Self.stillroomKey) {
            do {
                return try decoder.decode(StillroomDocument.self, from: data)
            } catch {
                if let recovered = decodeBackup() {
                    return recovered
                }
                return .empty
            }
        }
        if let recovered = decodeBackup() {
            return recovered
        }
        return .empty
    }

    func save(_ document: StillroomDocument) throws {
        let data = try encoder.encode(document)
        defaults.set(data, forKey: Self.stillroomKey)
        try writeBackup(data)
    }

    func resetStillroom() {
        defaults.removeObject(forKey: Self.stillroomKey)
        removeIfPresent(backupURL)
        removeIfPresent(backupCopyURL)
    }

    var demoPlanted: Bool {
        defaults.bool(forKey: Self.demoKey)
    }

    func markDemoPlanted() {
        defaults.set(true, forKey: Self.demoKey)
    }

    func exportCSV(_ document: StillroomDocument, to url: URL) throws {
        try StillroomCSV.write(document, to: url, fileManager: fileManager)
    }

    private var backupCopyURL: URL {
        backupURL.deletingPathExtension().appendingPathExtension("backup")
    }

    private func decodeBackup() -> StillroomDocument? {
        for url in [backupURL, backupCopyURL] {
            guard fileManager.fileExists(atPath: url.path) else { continue }
            do {
                let data = try Data(contentsOf: url)
                return try decoder.decode(StillroomDocument.self, from: data)
            } catch {
                continue
            }
        }
        return nil
    }

    private func writeBackup(_ data: Data) throws {
        let folder = backupURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: backupURL.path) {
            removeIfPresent(backupCopyURL)
            do {
                try fileManager.copyItem(at: backupURL, to: backupCopyURL)
            } catch {
                // Copy of the previous good file is best-effort; the atomic write still proceeds.
            }
        }
        try data.write(to: backupURL, options: .atomic)
    }

    private func removeIfPresent(_ url: URL) {
        guard fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            // Reset still clears UserDefaults even if a leftover file remains.
        }
    }
}
