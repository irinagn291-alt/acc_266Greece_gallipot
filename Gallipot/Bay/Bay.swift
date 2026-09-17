import Foundation

/// A Bay is one tin identity on the stillroom. Lots of that barcode stack behind it.
struct Bay: Identifiable, Codable, Sendable, Equatable, Hashable {
    var id: UUID
    var barcode: String
    var name: String
    var brand: String?
    var imageURL: String?
}
