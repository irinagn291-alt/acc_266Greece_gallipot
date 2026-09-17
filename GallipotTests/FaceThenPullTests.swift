import XCTest
@testable import Gallipot

@MainActor
final class FaceThenPullTests: XCTestCase {
    func test_laterLotNeverFacesWhileEarlierRemains() async throws {
        let (store, _, _) = try await makeStore()
        let paste = tin("2034567890135", "Tomato paste")
        try await store.landLot(identity: paste, bestBefore: noonUTC(2026, 9, 23), quantity: 1)
        try await store.landLot(identity: paste, bestBefore: noonUTC(2026, 10, 27), quantity: 1)

        XCTAssertEqual(store.faces.count, 1)
        XCTAssertEqual(store.faces.first?.daysLeft, 6)
        XCTAssertEqual(store.document.lots.count, 2)
        XCTAssertEqual(store.pantryStacks.first?.liveLots.count, 2)
    }

    func test_sameBarcodeAndDaykey_stacksQuantity() async throws {
        let (store, _, _) = try await makeStore()
        let oats = tin("2034567890128", "Rolled oats")
        try await store.landLot(identity: oats, bestBefore: noonUTC(2026, 9, 20), quantity: 1)
        try await store.landLot(identity: oats, bestBefore: noonUTC(2026, 9, 20), quantity: 2)
        XCTAssertEqual(store.document.lots.count, 1)
        XCTAssertEqual(store.document.lots.first?.quantity, 3)
        XCTAssertEqual(store.document.bays.count, 1)
    }

    func test_pullPeelsFaceThenNextLotStepsForward() async throws {
        let (store, _, _) = try await makeStore()
        let paste = tin("2034567890135", "Tomato paste")
        try await store.landLot(identity: paste, bestBefore: noonUTC(2026, 9, 23), quantity: 1)
        try await store.landLot(identity: paste, bestBefore: noonUTC(2026, 10, 27), quantity: 1)
        let bayID = try XCTUnwrap(store.faces.first?.bay.id)

        try await store.pullFace(bayID)
        XCTAssertEqual(store.faces.first?.daysLeft, 40)
        XCTAssertEqual(store.document.lots.count, 1)
        XCTAssertEqual(store.document.pullMarks.count, 1)
    }

    func test_pullOnEmptyBay_isRefused() async throws {
        let (store, _, _) = try await makeStore()
        do {
            _ = try await store.pullFace(UUID())
            XCTFail("empty bay must refuse pull")
        } catch StillroomFault.missingBay {
            XCTAssertTrue(store.document.pullMarks.isEmpty)
        }

        try await store.landLot(identity: tin("2034567890128", "Rolled oats"), bestBefore: noonUTC(2026, 9, 20), quantity: 1)
        let bayID = try XCTUnwrap(store.faces.first?.bay.id)
        try await store.pullFace(bayID)
        do {
            _ = try await store.pullFace(bayID)
            XCTFail("peeled bay must refuse pull")
        } catch StillroomFault.emptyBay {
            XCTAssertEqual(store.document.pullMarks.count, 1)
        }
    }

    func test_invalidQuantityAndIdentity_areRefused() async throws {
        let (store, _, _) = try await makeStore()
        do {
            try await store.landLot(identity: tin("2034567890128", "Rolled oats"), bestBefore: noonUTC(2026, 9, 20), quantity: 0)
            XCTFail("zero qty must fail")
        } catch StillroomFault.invalidQuantity {}

        do {
            try await store.landLot(identity: tin("2034567890128", "Rolled oats"), bestBefore: noonUTC(2026, 9, 20), quantity: -2)
            XCTFail("negative qty must fail")
        } catch StillroomFault.invalidQuantity {}

        do {
            try await store.landLot(identity: tin("", "Rolled oats"), bestBefore: noonUTC(2026, 9, 20), quantity: 1)
            XCTFail("empty code must fail")
        } catch StillroomFault.invalidIdentity {}

        XCTAssertTrue(store.document.lots.isEmpty)
        XCTAssertTrue(store.faces.isEmpty)
    }

    func test_midnightFoldsPastLotsToSpent_untilCull() async throws {
        let (store, _, _) = try await makeStore(now: noonUTC(2026, 9, 17))
        try await store.landLot(identity: tin("2034567890159", "Black tea"), bestBefore: noonUTC(2026, 9, 17), quantity: 1)
        XCTAssertEqual(store.faces.count, 1)
        XCTAssertEqual(store.faces.first?.daysLeft, 0)

        store.setNow(noonUTC(2026, 9, 18))
        store.foldMidnightIfNeeded()
        XCTAssertTrue(store.faces.isEmpty)
        XCTAssertEqual(store.document.spent.count, 1)
        XCTAssertTrue(store.document.lots.isEmpty)

        await store.cullSpent()
        XCTAssertTrue(store.document.spent.isEmpty)
        XCTAssertTrue(store.document.bays.isEmpty)
    }

    func test_undoPeelsLastPullOrLastLot() async throws {
        let (store, _, _) = try await makeStore()
        try await store.landLot(identity: tin("2034567890128", "Rolled oats"), bestBefore: noonUTC(2026, 9, 20), quantity: 2)
        let bayID = try XCTUnwrap(store.faces.first?.bay.id)
        try await store.pullFace(bayID)
        XCTAssertEqual(store.faces.first?.lot.quantity, 1)

        try await store.undo()
        XCTAssertEqual(store.faces.first?.lot.quantity, 2)
        XCTAssertTrue(store.document.pullMarks.isEmpty)

        try await store.undo()
        XCTAssertTrue(store.document.lots.isEmpty)
        XCTAssertTrue(store.document.bays.isEmpty)

        do {
            try await store.undo()
            XCTFail("empty undo must fail")
        } catch StillroomFault.nothingToUndo {}
    }

    func test_demoHarvest_enablesPull_andIsNotEmptyRail() async throws {
        let (store, _, _) = try await makeStore()
        store.applyDemoHarvest()
        XCTAssertGreaterThanOrEqual(store.document.bays.count, 4)
        XCTAssertGreaterThanOrEqual(store.document.lots.count, 4)
        XCTAssertEqual(store.document.spent.count, 1)
        XCTAssertTrue(store.canPull)
        XCTAssertTrue(store.document.onboardingComplete)
        let paste = try XCTUnwrap(store.pantryStacks.first { $0.bay.barcode == "2034567890135" })
        XCTAssertGreaterThanOrEqual(paste.liveLots.count, 2)
    }
}
