import Foundation

/// Identity of a tin. Name, brand, code, image only. No energy, no macros.
struct TinIdentity: Identifiable, Codable, Sendable, Equatable, Hashable {
    var id: String { barcode }
    var barcode: String
    var name: String
    var brand: String?
    var imageURL: String?
}
