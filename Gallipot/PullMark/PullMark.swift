import Foundation

/// A PullMark records that the Face of a Bay was peeled by one unit.
struct PullMark: Identifiable, Codable, Sendable, Equatable, Hashable {
    var id: UUID
    var bayID: UUID
    var lotID: UUID
    var daykey: Int
    var quantity: Int
}

/// In-memory undo record for the last Lot landing or Pull. Not a second source of truth for Faces.
struct Reversal: Codable, Sendable, Equatable {
    enum Kind: String, Codable, Sendable {
        case landed
        case stacked
        case pulled
    }

    var kind: Kind
    var bayID: UUID
    var lotID: UUID
    var bayWasNew: Bool
    var quantityDelta: Int
    var pullMarkID: UUID?
    var peeledLot: Lot?
}
