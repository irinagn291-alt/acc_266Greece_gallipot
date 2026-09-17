import XCTest
@testable import Gallipot

final class StillroomLinkTests: XCTestCase {
    func test_reviewKeys_mapToThreeDifferentTabs() {
        let today = StillroomLink.tab(for: .today)
        let log = StillroomLink.tab(for: .log)
        let goals = StillroomLink.tab(for: .goals)
        XCTAssertEqual(today, .useSoon)
        XCTAssertEqual(log, .pantry)
        XCTAssertEqual(goals, .settings)
        XCTAssertNotEqual(today, log)
        XCTAssertNotEqual(log, goals)
        XCTAssertNotEqual(goals, today)
    }

    func test_parsesSchemeAndHttps() throws {
        let scan = try XCTUnwrap(URL(string: "gallipot://scan"))
        XCTAssertEqual(StillroomLink.parse(scan), .scan)

        let settings = try XCTUnwrap(URL(string: "gallipot://settings"))
        XCTAssertEqual(StillroomLink.parse(settings), .settings)

        let pantry = try XCTUnwrap(URL(string: "https://gallipot-bay.pro/pantry"))
        XCTAssertEqual(StillroomLink.parse(pantry), .pantry)

        let id = UUID()
        let bay = try XCTUnwrap(URL(string: "gallipot://bay/\(id.uuidString)"))
        XCTAssertEqual(StillroomLink.parse(bay), .bay(id))
    }

    func test_scanLink_staysOnUseSoonTab() {
        XCTAssertEqual(StillroomLink.scan.tab, .useSoon)
        XCTAssertEqual(StillroomLink.useSoon.tab, .useSoon)
        XCTAssertEqual(StillroomLink.settings.tab, .settings)
        XCTAssertEqual(StillroomLink.pantry.tab, .pantry)
        XCTAssertEqual(StillroomLink.tab(for: .scan), .useSoon)
        XCTAssertEqual(StillroomLink.tab(for: .facing), .useSoon)
        XCTAssertEqual(StillroomLink.tab(for: .bay), .pantry)
        XCTAssertNotEqual(StillroomPlace.pantry, StillroomPlace.settings)
        XCTAssertNotEqual(StillroomPlace.settings, StillroomPlace.facing)
        XCTAssertNotEqual(StillroomPlace.pantry, StillroomPlace.facing)
    }
}
