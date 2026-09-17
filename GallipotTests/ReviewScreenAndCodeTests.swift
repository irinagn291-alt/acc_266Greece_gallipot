import XCTest
@testable import Gallipot

final class ReviewScreenFlagTests: XCTestCase {
    func test_parsesThreeKeysToThreeDestinations() {
        XCTAssertEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "today"]), .today)
        XCTAssertEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "log"]), .log)
        XCTAssertEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "goals"]), .goals)
        XCTAssertNotEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "today"]), .log)
        XCTAssertNotEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "log"]), .goals)
        XCTAssertNotEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "goals"]), .today)
    }

    func test_aliasesAndExtraCoverKeys() {
        XCTAssertEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "usesoon"]), .today)
        XCTAssertEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "pantry"]), .log)
        XCTAssertEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "settings"]), .goals)
        XCTAssertEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "scan"]), .scan)
        XCTAssertEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "capture"]), .scan)
        XCTAssertEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "facing"]), .facing)
        XCTAssertEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "bay"]), .bay)
        XCTAssertNotEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "scan"]), .today)
        XCTAssertNotEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "facing"]), .log)
        XCTAssertNotEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "bay"]), .today)
        XCTAssertNotEqual(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "bay"]), .log)
    }

    func test_consumeOnceAfterOnboarding() {
        var consumed = false
        XCTAssertNil(
            ReviewScreenFlag.consume(
                arguments: ["-ReviewScreen", "log"],
                onboarded: false,
                consumed: &consumed
            )
        )
        XCTAssertFalse(consumed)

        let first = ReviewScreenFlag.consume(
            arguments: ["app", "-ReviewScreen", "log"],
            onboarded: true,
            consumed: &consumed
        )
        XCTAssertEqual(first, .log)
        XCTAssertTrue(consumed)
        XCTAssertNil(
            ReviewScreenFlag.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboarded: true,
                consumed: &consumed
            )
        )
    }

    func test_fromProcessInfo_readsLaunchArgument() {
        XCTAssertEqual(
            ReviewScreenFlag.parse(arguments: ProcessInfo.processInfo.arguments)
                ?? ReviewScreenFlag.fromProcessInfo(),
            ReviewScreenFlag.fromProcessInfo()
        )
    }

    func test_missingOrUnknown_isNil() {
        XCTAssertNil(ReviewScreenFlag.parse(arguments: []))
        XCTAssertNil(ReviewScreenFlag.parse(arguments: ["-ReviewScreen"]))
        XCTAssertNil(ReviewScreenFlag.parse(arguments: ["-ReviewScreen", "unknown"]))
        XCTAssertNil(ReviewScreenFlag.parse(arguments: ["today"]))
    }
}

@MainActor
final class ReviewScreenNavigationTests: XCTestCase {
    func test_applySwitchesLiveNavigation() {
        let session = StillroomSession()
        session.apply(.today)
        XCTAssertEqual(session.tab, .useSoon)
        XCTAssertEqual(session.stackPath, [])
        XCTAssertFalse(session.scanPresented)

        session.apply(.log)
        XCTAssertEqual(session.tab, .pantry)
        XCTAssertEqual(session.stackPath, [.pantry])
        XCTAssertFalse(session.scanPresented)

        session.apply(.goals)
        XCTAssertEqual(session.tab, .settings)
        XCTAssertEqual(session.stackPath, [.settings])
        XCTAssertFalse(session.scanPresented)

        session.apply(.scan)
        XCTAssertEqual(session.tab, .useSoon)
        XCTAssertEqual(session.stackPath, [])
        XCTAssertTrue(session.scanPresented)

        session.apply(.facing)
        XCTAssertEqual(session.tab, .useSoon)
        XCTAssertEqual(session.stackPath, [.facing])
        XCTAssertTrue(session.showFacing)
        XCTAssertFalse(session.scanPresented)

        session.apply(.bay)
        XCTAssertEqual(session.tab, .pantry)
        XCTAssertFalse(session.scanPresented)
    }

    func test_applyReviewIfNeeded_waitsForOnboarding() {
        let session = StillroomSession()
        session.showOnboarding = true
        session.applyReviewIfNeeded(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(session.tab, .useSoon)
        XCTAssertFalse(session.scanPresented)
    }
}

final class TinCodeHarvestTests: XCTestCase {
    func test_extractsDigitRuns_andPadsUPCA() {
        let qr = TinCodeHarvest.candidates(from: "https://world.openfoodfacts.org/product/2034567890128")
        XCTAssertEqual(qr, ["2034567890128"])

        let upc = TinCodeHarvest.candidates(from: "012345678905")
        XCTAssertEqual(upc.first, "0012345678905")
        XCTAssertTrue(upc.contains("012345678905"))

        let mixed = TinCodeHarvest.candidates(from: "see 12345678 and 999")
        XCTAssertEqual(mixed, ["12345678"])
    }
}
