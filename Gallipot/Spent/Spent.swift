import Foundation

/// Spent membership is a past best-before daykey. Cull clears folded packs; days-left is not stored.
enum Spent {
    static func isPast(_ lot: Lot, todayDaykey: Int) -> Bool {
        lot.bestBeforeDaykey < todayDaykey
    }
}
