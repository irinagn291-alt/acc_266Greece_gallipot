import Foundation

/// Face is the soonest live Lot of a Bay. Derived at display, never stored.
struct Face: Identifiable, Sendable, Equatable {
    var id: UUID { bay.id }
    var bay: Bay
    var lot: Lot
    var daysLeft: Int
}
