import Foundation

/// Pantry row: live Lots stacked behind the Face, plus Spent packs for that Bay.
struct BayStack: Identifiable, Sendable, Equatable {
    var id: UUID { bay.id }
    var bay: Bay
    var face: Face?
    var liveLots: [Lot]
    var spentLots: [Lot]
}
