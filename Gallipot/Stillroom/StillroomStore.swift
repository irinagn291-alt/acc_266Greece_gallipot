import Foundation
import Observation

/// Only mutation seam for the stillroom. Views never touch UserDefaults.
@Observable
@MainActor
final class StillroomStore {
    private(set) var document: StillroomDocument

    private let vault: StillroomVault
    private var now: @Sendable () -> Date
    private let calendar: Calendar
    private let csvURL: URL
    private var saveTask: Task<Void, Never>?

    init(
        vault: StillroomVault,
        now: @escaping @Sendable () -> Date = { Date() },
        calendar: Calendar = .current,
        csvURL: URL
    ) async {
        self.vault = vault
        self.now = now
        self.calendar = calendar
        self.csvURL = csvURL
        self.document = await vault.load()
        let before = document
        foldMidnightIfNeeded()
        if document != before {
            await persistNow()
        }
    }

    func setNow(_ date: Date) {
        now = { date }
    }

    var faces: [Face] {
        let moment = now()
        var result: [Face] = []
        for bay in document.bays {
            let live = document.lots
                .filter { $0.bayID == bay.id && $0.quantity > 0 }
                .sorted { $0.bestBeforeDaykey < $1.bestBeforeDaykey }
            guard let lot = live.first else { continue }
            result.append(
                Face(
                    bay: bay,
                    lot: lot,
                    daysLeft: Daykey.daysLeft(bestBefore: lot.bestBeforeDaykey, today: moment, calendar: calendar)
                )
            )
        }
        return result.sorted { lhs, rhs in
            if lhs.daysLeft != rhs.daysLeft { return lhs.daysLeft < rhs.daysLeft }
            return lhs.bay.name.localizedCaseInsensitiveCompare(rhs.bay.name) == .orderedAscending
        }
    }

    var pantryStacks: [BayStack] {
        document.bays.map { bay in
            let live = document.lots
                .filter { $0.bayID == bay.id }
                .sorted { $0.bestBeforeDaykey < $1.bestBeforeDaykey }
            let spentLots = document.spent
                .filter { $0.bayID == bay.id }
                .sorted { $0.bestBeforeDaykey < $1.bestBeforeDaykey }
            return BayStack(
                bay: bay,
                face: faces.first { $0.bay.id == bay.id },
                liveLots: live,
                spentLots: spentLots
            )
        }
        .sorted { $0.bay.name.localizedCaseInsensitiveCompare($1.bay.name) == .orderedAscending }
    }

    var heroFace: Face? { faces.first }

    var canPull: Bool { heroFace != nil }

    func landLot(identity: TinIdentity, bestBefore: Date, quantity: Int) async throws {
        guard quantity > 0 else { throw StillroomFault.invalidQuantity }
        let code = identity.barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = identity.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty, !name.isEmpty else { throw StillroomFault.invalidIdentity }
        foldMidnightIfNeeded()
        let daykey = Daykey.make(bestBefore, calendar: calendar)

        let bay: Bay
        let bayWasNew: Bool
        if let existing = document.bays.first(where: { $0.barcode == code }) {
            bay = existing
            bayWasNew = false
        } else {
            bay = Bay(
                id: UUID(),
                barcode: code,
                name: name,
                brand: identity.brand,
                imageURL: identity.imageURL
            )
            document.bays.append(bay)
            bayWasNew = true
        }

        if let index = document.lots.firstIndex(where: { $0.bayID == bay.id && $0.bestBeforeDaykey == daykey }) {
            document.lots[index].quantity += quantity
            document.reversals.append(
                Reversal(
                    kind: .stacked,
                    bayID: bay.id,
                    lotID: document.lots[index].id,
                    bayWasNew: false,
                    quantityDelta: quantity,
                    pullMarkID: nil,
                    peeledLot: nil
                )
            )
        } else {
            let lot = Lot(
                id: UUID(),
                bayID: bay.id,
                barcode: code,
                bestBeforeDaykey: daykey,
                quantity: quantity
            )
            document.lots.append(lot)
            document.reversals.append(
                Reversal(
                    kind: .landed,
                    bayID: bay.id,
                    lotID: lot.id,
                    bayWasNew: bayWasNew,
                    quantityDelta: quantity,
                    pullMarkID: nil,
                    peeledLot: nil
                )
            )
        }
        foldMidnightIfNeeded()
        await persistNow()
    }

    @discardableResult
    func pullFace(_ bayID: UUID) async throws -> PullMark {
        foldMidnightIfNeeded()
        guard document.bays.contains(where: { $0.id == bayID }) else {
            throw StillroomFault.missingBay
        }
        let live = document.lots
            .filter { $0.bayID == bayID && $0.quantity > 0 }
            .sorted { $0.bestBeforeDaykey < $1.bestBeforeDaykey }
        guard let faceLot = live.first,
              let index = document.lots.firstIndex(where: { $0.id == faceLot.id })
        else {
            throw StillroomFault.emptyBay
        }

        let mark = PullMark(
            id: UUID(),
            bayID: bayID,
            lotID: faceLot.id,
            daykey: Daykey.make(now(), calendar: calendar),
            quantity: 1
        )
        document.lots[index].quantity -= 1
        document.pullMarks.append(mark)

        var peeled: Lot?
        if document.lots[index].quantity == 0 {
            var restored = document.lots[index]
            restored.quantity = 1
            peeled = restored
            document.lots.remove(at: index)
        }

        document.reversals.append(
            Reversal(
                kind: .pulled,
                bayID: bayID,
                lotID: faceLot.id,
                bayWasNew: false,
                quantityDelta: 1,
                pullMarkID: mark.id,
                peeledLot: peeled
            )
        )
        await persistNow()
        return mark
    }

    func undo() async throws {
        guard let reversal = document.reversals.popLast() else {
            throw StillroomFault.nothingToUndo
        }
        switch reversal.kind {
        case .landed:
            document.lots.removeAll { $0.id == reversal.lotID }
            if reversal.bayWasNew {
                let hasLive = document.lots.contains { $0.bayID == reversal.bayID }
                let hasSpent = document.spent.contains { $0.bayID == reversal.bayID }
                if !hasLive && !hasSpent {
                    document.bays.removeAll { $0.id == reversal.bayID }
                }
            }
        case .stacked:
            if let index = document.lots.firstIndex(where: { $0.id == reversal.lotID }) {
                document.lots[index].quantity -= reversal.quantityDelta
                if document.lots[index].quantity <= 0 {
                    document.lots.remove(at: index)
                }
            }
        case .pulled:
            document.pullMarks.removeAll { $0.id == reversal.pullMarkID }
            if let peeled = reversal.peeledLot {
                document.lots.append(peeled)
            } else if let index = document.lots.firstIndex(where: { $0.id == reversal.lotID }) {
                document.lots[index].quantity += reversal.quantityDelta
            }
        }
        foldMidnightIfNeeded()
        await persistNow()
    }

    func cullSpent() async {
        document.spent.removeAll()
        pruneOrphanBays()
        await persistNow()
    }

    func foldMidnightIfNeeded() {
        let today = Daykey.make(now(), calendar: calendar)
        var live: [Lot] = []
        var folded: [Lot] = []
        for lot in document.lots {
            if Spent.isPast(lot, todayDaykey: today) {
                folded.append(lot)
            } else {
                live.append(lot)
            }
        }
        document.lots = live
        if !folded.isEmpty {
            document.spent.append(contentsOf: folded)
        }
    }

    func markOnboardingComplete() async {
        document.onboardingComplete = true
        await persistNow()
    }

    func resetAllData() async {
        saveTask?.cancel()
        document = .empty
        await vault.resetStillroom()
    }

    func flush() async {
        await persistNow()
    }

    func exportCSV() async throws -> URL {
        try await vault.exportCSV(document, to: csvURL)
        return csvURL
    }

    func applyDemoHarvest() {
        document = .empty
        let today = now()
        let todayKey = Daykey.make(today, calendar: calendar)

        let oats = TinIdentity(barcode: "2034567890128", name: "Rolled oats", brand: "Mill", imageURL: nil)
        let paste = TinIdentity(barcode: "2034567890135", name: "Tomato paste", brand: "Kettle", imageURL: nil)
        let rice = TinIdentity(barcode: "2034567890166", name: "White rice", brand: "Bin", imageURL: nil)
        let tea = TinIdentity(barcode: "2034567890159", name: "Black tea", brand: "Caddy", imageURL: nil)
        let lentils = TinIdentity(barcode: "2034567890180", name: "Red lentils", brand: "Sack", imageURL: nil)

        let oatsBay = Bay(id: UUID(), barcode: oats.barcode, name: oats.name, brand: oats.brand, imageURL: nil)
        let pasteBay = Bay(id: UUID(), barcode: paste.barcode, name: paste.name, brand: paste.brand, imageURL: nil)
        let riceBay = Bay(id: UUID(), barcode: rice.barcode, name: rice.name, brand: rice.brand, imageURL: nil)
        let teaBay = Bay(id: UUID(), barcode: tea.barcode, name: tea.name, brand: tea.brand, imageURL: nil)
        let lentilBay = Bay(id: UUID(), barcode: lentils.barcode, name: lentils.name, brand: lentils.brand, imageURL: nil)

        document.bays = [oatsBay, pasteBay, riceBay, teaBay, lentilBay]
        document.lots = [
            Lot(id: UUID(), bayID: oatsBay.id, barcode: oats.barcode, bestBeforeDaykey: Daykey.shifting(todayKey, days: 2, calendar: calendar), quantity: 2),
            Lot(id: UUID(), bayID: pasteBay.id, barcode: paste.barcode, bestBeforeDaykey: Daykey.shifting(todayKey, days: 6, calendar: calendar), quantity: 1),
            Lot(id: UUID(), bayID: pasteBay.id, barcode: paste.barcode, bestBeforeDaykey: Daykey.shifting(todayKey, days: 40, calendar: calendar), quantity: 1),
            Lot(id: UUID(), bayID: riceBay.id, barcode: rice.barcode, bestBeforeDaykey: Daykey.shifting(todayKey, days: 21, calendar: calendar), quantity: 3),
            Lot(id: UUID(), bayID: lentilBay.id, barcode: lentils.barcode, bestBeforeDaykey: Daykey.shifting(todayKey, days: 10, calendar: calendar), quantity: 1),
        ]
        document.spent = [
            Lot(id: UUID(), bayID: teaBay.id, barcode: tea.barcode, bestBeforeDaykey: Daykey.shifting(todayKey, days: -2, calendar: calendar), quantity: 1),
        ]
        document.onboardingComplete = true
    }

    func plantDemoHarvestIfNeeded() async {
        #if targetEnvironment(simulator)
        let planted = await vault.demoPlanted
        if planted, !document.bays.isEmpty {
            if !document.onboardingComplete {
                document.onboardingComplete = true
                await persistNow()
            }
            return
        }
        applyDemoHarvest()
        await vault.markDemoPlanted()
        await persistNow()
        #endif
    }

    private func pruneOrphanBays() {
        let live = Set(document.lots.map(\.bayID))
        let spentIDs = Set(document.spent.map(\.bayID))
        document.bays.removeAll { !live.contains($0.id) && !spentIDs.contains($0.id) }
    }

    private func persistNow() async {
        saveTask?.cancel()
        saveTask = nil
        let snapshot = document
        do {
            try await vault.save(snapshot)
        } catch {
            persistSoon(snapshot)
        }
    }

    private func persistSoon(_ snapshot: StillroomDocument) {
        saveTask?.cancel()
        saveTask = Task { [vault] in
            do {
                try await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
                try await vault.save(snapshot)
            } catch {
                return
            }
        }
    }
}
