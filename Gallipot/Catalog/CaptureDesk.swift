import AVFoundation
import Foundation
import Observation
import UIKit

enum CaptureField: Hashable {
    case search
    case manual
    case name
}

/// Hunt plus inline best-before fuse. A scan writes a Lot through StillroomSession, never UserDefaults.
@Observable
@MainActor
final class CaptureDesk {
    enum Phase: Equatable {
        case hunt
        case fuse(TinIdentity)
        case name(code: String)
    }

    enum HuntAccess: Equatable {
        case checking
        case needContinue
        case authorized
        case blocked
        case noDevice
    }

    private let porter: CatalogPorter
    private let gate: ShelfSeekGate

    var phase: Phase = .hunt
    var access: HuntAccess = .checking
    var query = ""
    var hits: [TinIdentity] = []
    var manual = ""
    var draftName = ""
    var bestBefore = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    var quantity = 1
    var fault: String?
    var working = false
    var showSpinner = false
    var canPage = false
    private var page = 1
    private var inflightPayload: String?
    private var seekTask: Task<Void, Never>?
    private var spinnerTask: Task<Void, Never>?

    init(porter: CatalogPorter) {
        self.porter = porter
        self.gate = ShelfSeekGate(porter: porter, delayNs: 500_000_000)
    }

    var sceneActive = true

    var cameraLive: Bool {
        access == .authorized && phase == .hunt && !working && sceneActive
    }

    var sampleTins: [TinIdentity] {
        BundledShelf.baked
    }

    func appear() async {
        refreshAccess()
        hits = []
        canPage = false
    }

    func refreshAccess() {
        #if targetEnvironment(simulator)
        access = .noDevice
        #else
        guard AVCaptureDevice.default(for: .video) != nil else {
            access = .noDevice
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            access = .authorized
        case .notDetermined:
            access = .needContinue
        default:
            access = .blocked
        }
        #endif
    }

    func continueToSystemAlert() {
        guard access == .needContinue else { return }
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            Task { @MainActor in
                self?.access = granted ? .authorized : .blocked
            }
        }
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func submitQuery() {
        seekTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            hits = []
            canPage = false
            fault = nil
            return
        }
        seekTask = Task { [weak self] in
            await self?.runSeek(terms: trimmed, reset: true)
        }
    }

    func loadMore() {
        guard canPage, !working else { return }
        let terms = query
        let next = page + 1
        seekTask = Task { [weak self] in
            await self?.runSeek(terms: terms, reset: false, page: next)
        }
    }

    func submitManual() async {
        let candidates = TinCodeHarvest.candidates(from: manual)
        if candidates.isEmpty {
            fault = "Need an 8 to 14 digit code."
            return
        }
        await resolve(payload: manual, candidates: candidates)
    }

    func pick(_ tin: TinIdentity) {
        fault = nil
        phase = .fuse(tin)
        draftName = tin.name
    }

    func handlePayload(_ raw: String) async {
        let candidates = TinCodeHarvest.candidates(from: raw)
        guard !candidates.isEmpty else { return }
        if working, inflightPayload == raw { return }
        await resolve(payload: raw, candidates: candidates)
    }

    func land(using session: StillroomSession) async {
        guard quantity > 0 else {
            fault = "Quantity must be at least 1."
            return
        }
        let identity: TinIdentity
        switch phase {
        case .fuse(let tin):
            identity = tin
        case .name(let code):
            let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else {
                fault = "Name the tin."
                return
            }
            identity = TinIdentity(barcode: code, name: name, brand: nil, imageURL: nil)
        case .hunt:
            fault = "Pick a tin first."
            return
        }
        working = true
        fault = nil
        defer { working = false }
        do {
            try await session.land(identity: identity, bestBefore: bestBefore, quantity: quantity)
        } catch StillroomFault.invalidQuantity {
            fault = "Quantity must be at least 1."
        } catch StillroomFault.invalidIdentity {
            fault = "Name and code are required."
        } catch {
            fault = "Lot did not land."
        }
    }

    func backToHunt() {
        phase = .hunt
        fault = nil
        working = false
        showSpinner = false
    }

    private func resolve(payload: String, candidates: [String]) async {
        if working, inflightPayload == payload { return }
        inflightPayload = payload
        working = true
        fault = nil
        gateSpinner()
        defer {
            working = false
            showSpinner = false
            spinnerTask?.cancel()
            inflightPayload = nil
        }
        do {
            let tin = try await porter.resolve(candidates: candidates)
            phase = .fuse(tin)
            draftName = tin.name
        } catch WorldShelfFault.cancelled {
            return
        } catch WorldShelfFault.notFound {
            let code = candidates.first ?? payload
            phase = .name(code: code)
            draftName = ""
            fault = "No tin for that code. Name it and set a best before."
        } catch {
            let code = candidates.first ?? payload
            phase = .name(code: code)
            fault = "Lookup failed. Name it on this device."
        }
    }

    private func runSeek(terms: String, reset: Bool, page: Int = 1) async {
        let trimmed = terms.trimmingCharacters(in: .whitespacesAndNewlines)
        if reset {
            self.page = 1
        }
        working = true
        fault = nil
        gateSpinner()
        defer {
            working = false
            showSpinner = false
            spinnerTask?.cancel()
        }
        do {
            let found: [TinIdentity]
            if reset {
                found = try await gate.submit(terms: trimmed)
            } else {
                found = await porter.seek(terms: trimmed, page: page)
            }
            if Task.isCancelled { return }
            if reset {
                hits = found
                self.page = 1
            } else {
                var seen = Set(hits.map(\.barcode))
                for tin in found where seen.insert(tin.barcode).inserted {
                    hits.append(tin)
                }
                self.page = page
            }
            canPage = found.count >= 20
            if found.isEmpty && !trimmed.isEmpty {
                fault = "No tins matched. Try a code."
            }
        } catch WorldShelfFault.cancelled {
            return
        } catch {
            hits = await porter.seek(terms: trimmed)
            canPage = false
            fault = "Search fell back to the local shelf."
        }
    }

    private func gateSpinner() {
        spinnerTask?.cancel()
        showSpinner = false
        spinnerTask = Task { [weak self] in
            do {
                try await Task.sleep(for: StillroomMeasure.spinnerGate)
            } catch {
                return
            }
            guard let self, self.working else { return }
            self.showSpinner = true
        }
    }
}
