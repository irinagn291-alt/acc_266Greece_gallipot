import XCTest
@testable import Gallipot

func utcCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
}

func noonUTC(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var parts = DateComponents()
    parts.year = year
    parts.month = month
    parts.day = day
    parts.hour = 12
    return utcCalendar().date(from: parts)!
}

@MainActor
func makeStore(
    now: Date = noonUTC(2026, 9, 17),
    suiteName: String = UUID().uuidString
) async throws -> (StillroomStore, UserDefaults, URL) {
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(suiteName, isDirectory: true)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let vault = StillroomVault(
        suiteName: suiteName,
        backupURL: folder.appendingPathComponent("stillroom.v1.json")
    )
    let store = await StillroomStore(
        vault: vault,
        now: { now },
        calendar: utcCalendar(),
        csvURL: folder.appendingPathComponent("stillroom.csv")
    )
    return (store, defaults, folder)
}

func tin(_ code: String, _ name: String) -> TinIdentity {
    TinIdentity(barcode: code, name: name, brand: "Mill", imageURL: nil)
}
