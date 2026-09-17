import Foundation

/// Owns both Open Food Facts endpoints. Identity lookup only.
final class WorldShelfClient: Sendable {
    static let userAgent = "Gallipot/1.0 (iOS; +https://gallipot-bay.pro)"
    static let host = "https://world.openfoodfacts.org"
    private static let identityFields = "code,product_name,brands,image_url,image_front_url,image_front_small_url"

    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 15
        config.httpAdditionalHeaders = ["User-Agent": Self.userAgent]
        self.session = URLSession(configuration: config)
    }

    func seek(terms: String, page: Int) async throws -> WorldSearchDTO {
        let trimmed = terms.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return WorldSearchDTO(count: 0, page: page, pageSize: 20, products: [])
        }
        var components = URLComponents(string: "\(Self.host)/cgi/search.pl")
        components?.queryItems = [
            URLQueryItem(name: "search_terms", value: trimmed),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: "20"),
            URLQueryItem(name: "fields", value: Self.identityFields),
        ]
        guard let url = components?.url else { throw WorldShelfFault.transport }
        let data = try await send(url)
        return try decode(WorldSearchDTO.self, from: data)
    }

    func fetchProduct(code: String) async throws -> WorldProductEnvelopeDTO {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? trimmed
        var components = URLComponents(string: "\(Self.host)/api/v2/product/\(encoded).json")
        components?.queryItems = [
            URLQueryItem(name: "fields", value: Self.identityFields),
        ]
        guard let url = components?.url else { throw WorldShelfFault.transport }
        let data = try await send(url)
        return try decode(WorldProductEnvelopeDTO.self, from: data)
    }

    private func send(_ url: URL, retried: Bool = false) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw WorldShelfFault.transport }
            if http.statusCode == 404 {
                throw WorldShelfFault.notFound
            }
            if (200 ..< 300).contains(http.statusCode) {
                return data
            }
            if !retried && Self.isTransientStatus(http.statusCode) {
                return try await send(url, retried: true)
            }
            throw WorldShelfFault.http(http.statusCode)
        } catch is CancellationError {
            throw WorldShelfFault.cancelled
        } catch let fault as WorldShelfFault {
            throw fault
        } catch {
            if Task.isCancelled { throw WorldShelfFault.cancelled }
            if !retried && Self.isTransientURL(error) {
                return try await send(url, retried: true)
            }
            throw WorldShelfFault.transport
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw WorldShelfFault.decoding
        }
    }

    private static func isTransientStatus(_ code: Int) -> Bool {
        code == 408 || code == 429 || (500 ..< 600).contains(code)
    }

    private static func isTransientURL(_ error: Error) -> Bool {
        let code = (error as? URLError)?.code
        switch code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet, .dnsLookupFailed, .cannotFindHost, .cannotConnectToHost:
            return true
        default:
            return false
        }
    }
}
