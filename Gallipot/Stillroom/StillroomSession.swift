import Foundation
import Observation
import SwiftUI

/// Presentation director. StillroomStore is the only mutation seam. Views never touch UserDefaults.
@Observable
@MainActor
final class StillroomSession {
    static let shared = StillroomSession()

    private(set) var store: StillroomStore?
    private(set) var porter: CatalogPorter?
    private(set) var isReady = false
    var showOnboarding = false
    var stackPath: [StillroomPlace] = []
    var scanPresented = false
    var pantryPath: [Bay] = []
    var railFault: String?
    var pantryFault: String?
    var deskFault: String?
    var verbBusy = false
    var commitFlash = false
    var exportedURL: URL?
    var bootFault: String?

    private var stash: IdentityStash?
    private var reviewConsumed = false
    private var booted = false
    private var pendingLink: StillroomLink?
    private var pendingBayName: String?

    var faces: [Face] { store?.faces ?? [] }
    var stacks: [BayStack] { store?.pantryStacks ?? [] }
    var hero: Face? { store?.heroFace }
    var canPull: Bool { store?.canPull ?? false }
    var canUndo: Bool { !(store?.document.reversals.isEmpty ?? true) }
    var spentCount: Int { store?.document.spent.count ?? 0 }
    var bayCount: Int { store?.document.bays.count ?? 0 }
    var liveCount: Int { store?.document.lots.count ?? 0 }

    var tab: StillroomTab {
        if stackPath.contains(.settings) { return .settings }
        if stackPath.contains(.pantry) { return .pantry }
        if stackPath.contains(where: { if case .bay = $0 { return true }; return false }) {
            return .pantry
        }
        return .useSoon
    }

    var showFacing: Bool {
        stackPath.contains(.facing)
    }

    func boot() async {
        if booted, store != nil {
            isReady = true
            return
        }
        bootFault = nil
        do {
            let folder = try StillroomPaths.supportFolder()
            let vault = StillroomVault(backupURL: folder.appendingPathComponent("stillroom.v1.json"))
            let identityStash = IdentityStash(url: folder.appendingPathComponent("identity-stash.json"))
            let catalog = CatalogPorter(
                client: WorldShelfClient(),
                stash: identityStash,
                shelf: BundledShelf.load(from: .main)
            )
            let stillroom = await StillroomStore(
                vault: vault,
                csvURL: folder.appendingPathComponent("stillroom.csv")
            )
            await stillroom.plantDemoHarvestIfNeeded()
            store = stillroom
            porter = catalog
            stash = identityStash
            booted = true
            isReady = true
            showOnboarding = !stillroom.document.onboardingComplete
            applyReviewIfNeeded()
            applyPendingLink()
            watchDayChange()
        } catch {
            bootFault = "Gallipot could not open its files."
            isReady = false
        }
    }

    func handle(phase: ScenePhase) async {
        guard let store else { return }
        switch phase {
        case .active:
            store.foldMidnightIfNeeded()
            await store.flush()
        case .inactive, .background:
            await store.flush()
        @unknown default:
            await store.flush()
        }
    }

    func open(url: URL) {
        guard let link = StillroomLink.parse(url) else { return }
        open(link)
    }

    func open(_ link: StillroomLink) {
        guard isReady, store != nil, !showOnboarding else {
            pendingLink = link
            return
        }
        apply(link)
    }

    func applyReviewIfNeeded(arguments: [String] = ProcessInfo.processInfo.arguments) {
        let onboarded = store?.document.onboardingComplete == true && !showOnboarding
        guard let flag = ReviewScreenFlag.consume(
            arguments: arguments,
            onboarded: onboarded,
            consumed: &reviewConsumed
        ) else { return }
        apply(flag)
    }

    func apply(_ flag: ReviewScreenFlag) {
        pantryPath = []
        switch flag {
        case .today:
            stackPath = []
            scanPresented = false
        case .log:
            stackPath = [.pantry]
            scanPresented = false
        case .goals:
            stackPath = [.settings]
            scanPresented = false
        case .scan:
            stackPath = []
            scanPresented = true
        case .facing:
            stackPath = [.facing]
            scanPresented = false
        case .bay:
            scanPresented = false
            if let stack = stacks.first(where: { $0.face != nil }) ?? stacks.first {
                pantryPath = [stack.bay]
                stackPath = [.pantry, .bay(stack.bay.id)]
            } else {
                stackPath = [.pantry]
            }
        }
    }

    func finishOnboarding() async {
        guard let store else { return }
        await store.markOnboardingComplete()
        showOnboarding = false
        applyReviewIfNeeded()
        applyPendingLink()
    }

    func replayOnboarding() {
        showOnboarding = true
        scanPresented = false
        stackPath = []
        pantryPath = []
    }

    func pullFace(_ bayID: UUID) async {
        guard let store, !verbBusy else { return }
        verbBusy = true
        railFault = nil
        defer { verbBusy = false }
        do {
            _ = try await store.pullFace(bayID)
            StillroomCommit.pulse()
            flashCommit()
        } catch StillroomFault.emptyBay {
            railFault = "No pack in front."
        } catch StillroomFault.missingBay {
            railFault = "That tin is gone."
        } catch {
            railFault = "Pull failed."
        }
    }

    func undoLast() async {
        guard let store, !verbBusy else { return }
        verbBusy = true
        railFault = nil
        defer { verbBusy = false }
        do {
            try await store.undo()
            StillroomCommit.pulse()
        } catch StillroomFault.nothingToUndo {
            railFault = "Nothing to undo."
        } catch {
            railFault = "Undo failed."
        }
    }

    func land(identity: TinIdentity, bestBefore: Date, quantity: Int) async throws {
        guard let store else { throw StillroomFault.invalidIdentity }
        try await store.landLot(identity: identity, bestBefore: bestBefore, quantity: quantity)
        StillroomCommit.pulse()
        flashCommit()
        scanPresented = false
    }

    func cullSpent() async {
        guard let store else { return }
        pantryFault = nil
        await store.cullSpent()
        StillroomCommit.pulse()
    }

    func exportCSV() async {
        guard let store else { return }
        deskFault = nil
        do {
            exportedURL = try await store.exportCSV()
        } catch {
            deskFault = "CSV was not written."
            exportedURL = nil
        }
    }

    func resetStillroom() async {
        guard let store else { return }
        await store.resetAllData()
        if let stash {
            await stash.reset()
        }
        exportedURL = nil
        pantryPath = []
        stackPath = []
        scanPresented = false
        showOnboarding = true
        railFault = nil
        pantryFault = nil
        deskFault = nil
    }

    func openBay(_ id: UUID) {
        scanPresented = false
        if let stack = stacks.first(where: { $0.bay.id == id }) {
            pantryPath = [stack.bay]
            stackPath = [.pantry, .bay(id)]
        } else {
            pantryPath = []
            stackPath = [.pantry]
            pantryFault = "That tin is not stored."
        }
    }

    func openBay(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard isReady, store != nil, !showOnboarding else {
            pendingBayName = trimmed
            return
        }
        if let stack = stacks.first(where: {
            $0.bay.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
                || $0.bay.barcode == trimmed
        }) {
            openBay(stack.bay.id)
        } else {
            pantryPath = []
            stackPath = [.pantry]
            pantryFault = "That tin is not stored."
        }
    }

    func presentScan() {
        stackPath = []
        pantryPath = []
        scanPresented = true
    }

    func presentFacing() {
        scanPresented = false
        if stackPath.contains(.facing) { return }
        stackPath.append(.facing)
    }

    func presentPantry() {
        scanPresented = false
        pantryPath = []
        stackPath = [.pantry]
    }

    func presentSettings() {
        scanPresented = false
        stackPath = [.settings]
    }

    func notePath(_ path: [StillroomPlace]) {
        if !path.contains(where: { if case .bay = $0 { return true }; return false }) {
            if !path.contains(.pantry) {
                pantryPath = []
            }
        }
    }

    func retryBoot() async {
        booted = false
        await boot()
    }

    func retryRail() {
        railFault = nil
        store?.foldMidnightIfNeeded()
    }

    func retryPantry() {
        pantryFault = nil
        store?.foldMidnightIfNeeded()
    }

    func retryDesk() async {
        deskFault = nil
        await exportCSV()
    }

    private func apply(_ link: StillroomLink) {
        switch link {
        case .useSoon:
            stackPath = []
            pantryPath = []
            scanPresented = false
        case .scan:
            stackPath = []
            pantryPath = []
            scanPresented = true
        case .pantry:
            presentPantry()
        case .bay(let id):
            scanPresented = false
            openBay(id)
        case .settings:
            presentSettings()
        }
    }

    private func applyPendingLink() {
        guard !showOnboarding else { return }
        if ReviewScreenFlag.isPresent() {
            pendingLink = nil
            pendingBayName = nil
            return
        }
        if let pendingLink {
            self.pendingLink = nil
            apply(pendingLink)
        }
        if let pendingBayName {
            self.pendingBayName = nil
            openBay(named: pendingBayName)
        }
    }

    private func watchDayChange() {
        Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .NSCalendarDayChanged) {
                guard let self else { return }
                self.store?.foldMidnightIfNeeded()
                await self.store?.flush()
            }
        }
    }

    private func flashCommit() {
        commitFlash = true
        Task {
            do {
                try await Task.sleep(for: .milliseconds(700))
            } catch {
                commitFlash = false
                return
            }
            commitFlash = false
        }
    }
}
