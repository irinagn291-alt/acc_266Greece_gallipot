import Foundation

/// Display formatters for Face metrics. Round only here. Numbers never interpolate.
enum FaceInk {
    static func integer(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func daysLeft(_ value: Int) -> String {
        integer(value)
    }

    static func quantity(_ value: Int) -> String {
        integer(value)
    }

    static func bestBefore(_ key: Int, calendar: Calendar = .current) -> String {
        guard let date = Daykey.date(from: key, calendar: calendar) else { return "unknown" }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func stackedBehind(_ liveLots: Int) -> String {
        let behind = max(0, liveLots - 1)
        return integer(behind)
    }
}
