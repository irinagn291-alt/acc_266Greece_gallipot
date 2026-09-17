import XCTest
@testable import Gallipot

@MainActor
final class FamilyInvariantTests: XCTestCase {
    func test_bestBefore_yieldsDaysLeft() {
        let calendar = utcCalendar()
        let today = noonUTC(2026, 9, 17)
        let key = Daykey.make(noonUTC(2026, 9, 22), calendar: calendar)
        XCTAssertEqual(Daykey.daysLeft(bestBefore: key, today: today, calendar: calendar), 5)
        XCTAssertEqual(Daykey.make(today, calendar: calendar), 20260917)
    }

    func test_useSoon_ordersByDaysLeft_andPullMarksUsed() async throws {
        let (store, _, _) = try await makeStore()
        try await store.landLot(identity: tin("11111111", "Rice"), bestBefore: noonUTC(2026, 10, 1), quantity: 1)
        try await store.landLot(identity: tin("22222222", "Oats"), bestBefore: noonUTC(2026, 9, 20), quantity: 2)
        try await store.landLot(identity: tin("33333333", "Tea"), bestBefore: noonUTC(2026, 9, 25), quantity: 1)

        XCTAssertEqual(store.faces.map(\.bay.name), ["Oats", "Tea", "Rice"])
        XCTAssertEqual(store.faces.map(\.daysLeft), [3, 8, 14])
        XCTAssertTrue(store.canPull)

        let oatsID = try XCTUnwrap(store.faces.first?.bay.id)
        try await store.pullFace(oatsID)

        XCTAssertEqual(store.document.pullMarks.count, 1)
        XCTAssertEqual(store.faces.first?.lot.quantity, 1)
        XCTAssertEqual(store.faces.first?.bay.name, "Oats")
    }

    func test_stillroom_hasNoMealSlotsOrKcal() {
        let labels = Mirror(reflecting: StillroomDocument.empty).children.compactMap(\.label)
        XCTAssertFalse(labels.contains { $0.lowercased().contains("meal") })
        XCTAssertFalse(labels.contains { $0.lowercased().contains("kcal") })
        XCTAssertFalse(labels.contains { $0.lowercased().contains("slot") })

        let identity = TinIdentity(barcode: "1", name: "Oats", brand: nil, imageURL: nil)
        let identityLabels = Mirror(reflecting: identity).children.compactMap(\.label)
        XCTAssertFalse(identityLabels.contains { $0.lowercased().contains("kcal") })
        XCTAssertFalse(identityLabels.contains { $0.lowercased().contains("calorie") })
        XCTAssertEqual(identity.name, "Oats")
    }
}
