import Foundation

/// Local calendar day as Int YYYYMMDD. Face days-left is derived from this, never persisted.
enum Daykey {
    static func make(_ date: Date, calendar: Calendar) -> Int {
        let day = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let dayNumber = parts.day ?? 0
        return year * 10_000 + month * 100 + dayNumber
    }

    static func date(from key: Int, calendar: Calendar) -> Date? {
        var parts = DateComponents()
        parts.year = key / 10_000
        parts.month = (key / 100) % 100
        parts.day = key % 100
        guard let date = calendar.date(from: parts) else { return nil }
        return calendar.startOfDay(for: date)
    }

    static func daysLeft(bestBefore: Int, today: Date, calendar: Calendar) -> Int {
        guard let expiry = date(from: bestBefore, calendar: calendar) else { return 0 }
        let start = calendar.startOfDay(for: today)
        let end = calendar.startOfDay(for: expiry)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    static func shifting(_ key: Int, days: Int, calendar: Calendar) -> Int {
        guard let date = date(from: key, calendar: calendar),
              let moved = calendar.date(byAdding: .day, value: days, to: date)
        else { return key }
        return make(moved, calendar: calendar)
    }
}
