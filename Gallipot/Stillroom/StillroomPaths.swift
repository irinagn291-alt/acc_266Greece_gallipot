import Foundation

/// Application Support folder for the stillroom projection and identity stash.
enum StillroomPaths {
    static func supportFolder() throws -> URL {
        let manager = FileManager.default
        let base = try manager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = base.appendingPathComponent("Gallipot", isDirectory: true)
        try manager.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}
