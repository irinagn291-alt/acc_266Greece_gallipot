import XCTest
@testable import Gallipot

@MainActor
final class StillroomPersistenceTests: XCTestCase {
    func test_roundTrip_writeReload() async throws {
        let suite = UUID().uuidString
        let (store, _, folder) = try await makeStore(suiteName: suite)
        try await store.landLot(identity: tin("2034567890128", "Rolled oats"), bestBefore: noonUTC(2026, 9, 20), quantity: 2)
        await store.markOnboardingComplete()

        let vault = StillroomVault(
            suiteName: suite,
            backupURL: folder.appendingPathComponent("stillroom.v1.json")
        )
        let reloaded = await StillroomStore(
            vault: vault,
            now: { noonUTC(2026, 9, 17) },
            calendar: utcCalendar(),
            csvURL: folder.appendingPathComponent("stillroom.csv")
        )
        XCTAssertEqual(reloaded.document.lots.first?.quantity, 2)
        XCTAssertEqual(reloaded.document.bays.first?.name, "Rolled oats")
        XCTAssertTrue(reloaded.document.onboardingComplete)
        XCTAssertEqual(reloaded.faces.first?.daysLeft, 3)
    }

    func test_corruptDefaults_fallsBackToEmpty_orBackup() async throws {
        let suite = UUID().uuidString
        let (store, defaults, folder) = try await makeStore(suiteName: suite)
        try await store.landLot(identity: tin("2034567890128", "Rolled oats"), bestBefore: noonUTC(2026, 9, 20), quantity: 1)

        defaults.set(Data("not-json".utf8), forKey: StillroomVault.stillroomKey)
        let vault = StillroomVault(
            suiteName: suite,
            backupURL: folder.appendingPathComponent("stillroom.v1.json")
        )
        let recovered = await vault.load()
        XCTAssertEqual(recovered.bays.first?.name, "Rolled oats")

        defaults.set(Data("not-json".utf8), forKey: StillroomVault.stillroomKey)
        let jsonURL = folder.appendingPathComponent("stillroom.v1.json")
        let backupURL = folder.appendingPathComponent("stillroom.v1.backup")
        if FileManager.default.fileExists(atPath: jsonURL.path) {
            try FileManager.default.removeItem(at: jsonURL)
        }
        if FileManager.default.fileExists(atPath: backupURL.path) {
            try FileManager.default.removeItem(at: backupURL)
        }
        let empty = await vault.load()
        XCTAssertEqual(empty, .empty)
    }

    func test_unknownSchema_isRecoverable() async throws {
        let suite = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let payload = Data(#"{"schemaVersion":99,"bays":[],"lots":[]}"#.utf8)
        defaults.set(payload, forKey: StillroomVault.stillroomKey)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(suite, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let vault = StillroomVault(suiteName: suite, backupURL: folder.appendingPathComponent("stillroom.v1.json"))
        let document = await vault.load()
        XCTAssertEqual(document, .empty)
    }

    func test_encodedDocument_doesNotStoreFaceOrDaysLeft() async throws {
        let (store, _, _) = try await makeStore()
        try await store.landLot(identity: tin("2034567890128", "Rolled oats"), bestBefore: noonUTC(2026, 9, 20), quantity: 1)
        let data = try JSONEncoder().encode(store.document)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNil(object["faces"])
        XCTAssertNil(object["daysLeft"])
        XCTAssertEqual(object["schemaVersion"] as? Int, 1)
        XCTAssertNotNil(object["bays"])
        XCTAssertNotNil(object["lots"])
        XCTAssertNotNil(object["spent"])
        XCTAssertNotNil(object["pullMarks"])
    }

    func test_csvExport_readsTheSameDocument() async throws {
        let (store, _, folder) = try await makeStore()
        try await store.landLot(identity: tin("2034567890128", "Rolled oats"), bestBefore: noonUTC(2026, 9, 20), quantity: 2)
        store.applyDemoHarvest()
        let url = try await store.exportCSV()
        XCTAssertEqual(url.deletingLastPathComponent(), folder)
        let text = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(text.contains("2034567890128"))
        XCTAssertTrue(text.contains("spent"))
        XCTAssertTrue(text.contains("live"))
    }

    func test_resetAllData_clearsStillroom() async throws {
        let (store, defaults, _) = try await makeStore()
        store.applyDemoHarvest()
        await store.flush()
        await store.resetAllData()
        XCTAssertEqual(store.document, .empty)
        XCTAssertNil(defaults.data(forKey: StillroomVault.stillroomKey))
    }

    func test_identityStash_roundTrip() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("glp.identity.v1.json")
        let stash = IdentityStash(url: url)
        await stash.remember(tin("2034567890128", "Rolled oats"))
        let reloaded = IdentityStash(url: url)
        let recalled = await reloaded.recall("2034567890128")
        XCTAssertEqual(recalled?.name, "Rolled oats")
    }
}
