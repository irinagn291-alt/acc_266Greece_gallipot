import Foundation

/// Search and barcode resolve with local shelf fallback and identity cache.
actor CatalogPorter {
    private let client: WorldShelfClient
    private let stash: IdentityStash
    private let shelf: BundledShelf

    init(client: WorldShelfClient, stash: IdentityStash, shelf: BundledShelf) {
        self.client = client
        self.stash = stash
        self.shelf = shelf
    }

    func seek(terms: String, page: Int = 1) async -> [TinIdentity] {
        let trimmed = terms.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return shelf.tins
        }
        do {
            let dto = try await client.seek(terms: trimmed, page: page)
            let remote = (dto.products ?? []).compactMap(TinIdentityMap.make)
            if remote.isEmpty {
                return shelf.matching(trimmed)
            }
            return merge(remote: remote, local: shelf.matching(trimmed))
        } catch {
            if let cached = await stash.recall(trimmed) {
                return merge(remote: [cached], local: shelf.matching(trimmed))
            }
            return shelf.matching(trimmed)
        }
    }

    func resolve(code: String) async throws -> TinIdentity {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let envelope = try await client.fetchProduct(code: trimmed)
            if envelope.status == 0 {
                return try await recallOffline(trimmed)
            }
            if let product = envelope.product, let identity = TinIdentityMap.make(product) {
                await stash.remember(identity)
                return identity
            }
            return try await recallOffline(trimmed)
        } catch WorldShelfFault.notFound {
            return try await recallOffline(trimmed)
        } catch WorldShelfFault.cancelled {
            throw WorldShelfFault.cancelled
        } catch {
            if let cached = await stash.recall(trimmed) { return cached }
            if let local = shelf.identity(code: trimmed) { return local }
            throw error
        }
    }

    func resolve(candidates: [String]) async throws -> TinIdentity {
        var last: Error = WorldShelfFault.notFound
        for code in candidates {
            do {
                return try await resolve(code: code)
            } catch WorldShelfFault.cancelled {
                throw WorldShelfFault.cancelled
            } catch {
                last = error
            }
        }
        throw last
    }

    private func recallOffline(_ code: String) async throws -> TinIdentity {
        if let cached = await stash.recall(code) { return cached }
        if let local = shelf.identity(code: code) { return local }
        throw WorldShelfFault.notFound
    }

    private func merge(remote: [TinIdentity], local: [TinIdentity]) -> [TinIdentity] {
        var seen = Set<String>()
        var result: [TinIdentity] = []
        for tin in remote + local {
            if seen.insert(tin.barcode).inserted {
                result.append(tin)
            }
        }
        return result
    }
}

/// Cancels the in-flight seek when the query changes. Debounces by roughly 300 ms.
@MainActor
final class ShelfSeekGate {
    private let porter: CatalogPorter
    private let delayNs: UInt64
    private var task: Task<[TinIdentity], Error>?

    init(porter: CatalogPorter, delayNs: UInt64 = 300_000_000) {
        self.porter = porter
        self.delayNs = delayNs
    }

    func submit(terms: String) async throws -> [TinIdentity] {
        task?.cancel()
        let porter = self.porter
        let delayNs = self.delayNs
        let work = Task<[TinIdentity], Error> {
            if delayNs > 0 {
                try await Task.sleep(nanoseconds: delayNs)
            }
            try Task.checkCancellation()
            return await porter.seek(terms: terms)
        }
        task = work
        do {
            return try await work.value
        } catch is CancellationError {
            throw WorldShelfFault.cancelled
        }
    }
}
