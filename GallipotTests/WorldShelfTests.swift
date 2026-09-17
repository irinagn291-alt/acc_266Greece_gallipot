import XCTest
@testable import Gallipot

final class HarvestURLProtocol: URLProtocol {
    static let lock = NSLock()
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) throws -> (Int, Data))?
    nonisolated(unsafe) static var hits = 0

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let current = Self.currentHandler()
        Self.bumpHits()
        guard let current else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (status, data) = try current(request)
            guard let url = request.url,
                  let response = HTTPURLResponse(
                    url: url,
                    statusCode: status,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "application/json"]
                  )
            else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    static func reset() {
        install(nil)
        lock.lock()
        hits = 0
        lock.unlock()
    }

    static func hitCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return hits
    }

    static func install(_ handler: (@Sendable (URLRequest) throws -> (Int, Data))?) {
        lock.lock()
        Self.handler = handler
        lock.unlock()
    }

    static func currentHandler() -> (@Sendable (URLRequest) throws -> (Int, Data))? {
        lock.lock()
        defer { lock.unlock() }
        return handler
    }

    static func bumpHits() {
        lock.lock()
        hits += 1
        lock.unlock()
    }

    static func currentHits() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return hits
    }
}

final class WorldShelfTests: XCTestCase {
    override func tearDown() {
        HarvestURLProtocol.reset()
        super.tearDown()
    }

    func test_decoder_acceptsStringAndNumberNutriments_andDropsThemFromIdentity() throws {
        let json = Data(
            """
            {
              "status": "1",
              "product": {
                "code": "2034567890128",
                "product_name": "Rolled oats",
                "brands": "Mill",
                "image_url": "https://example.com/oats.png",
                "nutriments": {
                  "energy-kcal_100g": "12.5",
                  "energy_kcal_100g": 13,
                  "energy-kj_100g": 50
                }
              }
            }
            """.utf8
        )
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let envelope = try decoder.decode(WorldProductEnvelopeDTO.self, from: json)
        XCTAssertEqual(envelope.status, 1)
        XCTAssertEqual(envelope.product?.nutriments?.energyKcal100g, 12.5)
        let identity = try XCTUnwrap(TinIdentityMap.make(try XCTUnwrap(envelope.product)))
        XCTAssertEqual(identity.barcode, "2034567890128")
        XCTAssertEqual(identity.name, "Rolled oats")
        XCTAssertEqual(identity.brand, "Mill")
        let labels = Mirror(reflecting: identity).children.compactMap(\.label)
        XCTAssertFalse(labels.contains { $0.lowercased().contains("energy") })
        XCTAssertFalse(labels.contains { $0.lowercased().contains("kcal") })
    }

    func test_statusZero_mapsToNotFoundWhenOfflineMisses() async throws {
        let porter = try makePorter { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), WorldShelfClient.userAgent)
            let data = Data(#"{"status":0,"status_verbose":"product not found"}"#.utf8)
            return (200, data)
        }
        do {
            _ = try await porter.resolve(code: "00000000")
            XCTFail("unknown code must miss")
        } catch WorldShelfFault.notFound {}
    }

    func test_malformedJSON_isHandled() async throws {
        let porter = try makePorter { _ in (200, Data("not-json".utf8)) }
        do {
            _ = try await porter.resolve(code: "9999999999999")
            XCTFail("malformed json must not crash")
        } catch WorldShelfFault.decoding {}
    }

    func test_emptyQuery_doesNotHitNetwork() async throws {
        let porter = try makePorter { _ in
            XCTFail("empty query must not hit the network")
            return (500, Data())
        }
        let tins = await porter.seek(terms: "  ")
        XCTAssertFalse(tins.isEmpty)
        XCTAssertEqual(HarvestURLProtocol.hitCount(), 0)
    }

    func test_failedSearch_fallsBackToLocalShelf() async throws {
        let porter = try makePorter { _ in
            throw URLError(.timedOut)
        }
        let tins = await porter.seek(terms: "oats")
        XCTAssertTrue(tins.contains { $0.barcode == "2034567890128" })
    }

    func test_productLookup_usesV2Path_andCaches() async throws {
        let porter = try makePorter { request in
            XCTAssertTrue(request.url?.absoluteString.contains("/api/v2/product/2034567890999.json") == true)
            XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), WorldShelfClient.userAgent)
            let data = Data(
                """
                {"status":1,"product":{"code":"2034567890999","product_name":"Remote tin","brands":"Mill"}}
                """.utf8
            )
            return (200, data)
        }
        let identity = try await porter.resolve(code: "2034567890999")
        XCTAssertEqual(identity.name, "Remote tin")

        HarvestURLProtocol.install { _ in
            throw URLError(.notConnectedToInternet)
        }
        let cached = try await porter.resolve(code: "2034567890999")
        XCTAssertEqual(cached.name, "Remote tin")
    }

    func test_oneRetryOnTransientThenSuccess() async throws {
        HarvestURLProtocol.reset()
        HarvestURLProtocol.install { request in
            let hits = HarvestURLProtocol.currentHits()
            if hits == 1 {
                throw URLError(.timedOut)
            }
            XCTAssertTrue(request.url?.absoluteString.contains("/cgi/search.pl") == true)
            let data = Data(#"{"count":1,"page":1,"page_size":20,"products":[{"code":"2034567890128","product_name":"Remote oats"}]}"#.utf8)
            return (200, data)
        }

        let client = WorldShelfClient(session: makeSession())
        let dto = try await client.seek(terms: "oats", page: 1)
        XCTAssertEqual(dto.products?.first?.productName, "Remote oats")
        XCTAssertEqual(HarvestURLProtocol.hitCount(), 2)
    }

    func test_doesNotRetry404() async throws {
        let client = WorldShelfClient(session: makeSession())
        HarvestURLProtocol.reset()
        HarvestURLProtocol.install { _ in (404, Data()) }
        do {
            _ = try await client.fetchProduct(code: "00000000")
            XCTFail("404 must miss once")
        } catch WorldShelfFault.notFound {}
        XCTAssertEqual(HarvestURLProtocol.hitCount(), 1)
    }

    @MainActor
    func test_seekGate_emptyQuery_skipsNetwork() async throws {
        let porter = try makePorter { _ in
            XCTFail("gate empty query must not hit the network")
            return (500, Data())
        }
        let gate = ShelfSeekGate(porter: porter, delayNs: 0)
        let tins = try await gate.submit(terms: "")
        XCTAssertFalse(tins.isEmpty)
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [HarvestURLProtocol.self]
        config.timeoutIntervalForRequest = 15
        return URLSession(configuration: config)
    }

    private func makePorter(
        handler: @escaping @Sendable (URLRequest) throws -> (Int, Data)
    ) throws -> CatalogPorter {
        HarvestURLProtocol.reset()
        HarvestURLProtocol.install(handler)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let stash = IdentityStash(url: folder.appendingPathComponent("glp.identity.v1.json"))
        return CatalogPorter(
            client: WorldShelfClient(session: makeSession()),
            stash: stash,
            shelf: BundledShelf(tins: BundledShelf.baked)
        )
    }
}
