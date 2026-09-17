import Foundation

/// A Lot is a quantity sharing one Bay and one best-before daykey. Same pair stacks qty.
struct Lot: Identifiable, Codable, Sendable, Equatable, Hashable {
    var id: UUID
    var bayID: UUID
    var barcode: String
    var bestBeforeDaykey: Int
    var quantity: Int
}
