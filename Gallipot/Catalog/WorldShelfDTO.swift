import Foundation

enum WorldShelfFault: Error, Equatable, Sendable {
    case notFound
    case decoding
    case transport
    case http(Int)
    case cancelled
}

struct WorldSearchDTO: Decodable, Sendable {
    let count: Int?
    let page: Int?
    let pageSize: Int?
    let products: [WorldProductDTO]?

    enum CodingKeys: String, CodingKey {
        case count, page, products
        case pageSize = "page_size"
    }

    init(count: Int?, page: Int?, pageSize: Int?, products: [WorldProductDTO]?) {
        self.count = count
        self.page = page
        self.pageSize = pageSize
        self.products = products
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        count = FlexibleJSON.int(container, forKey: .count)
        page = FlexibleJSON.int(container, forKey: .page)
        pageSize = FlexibleJSON.int(container, forKey: .pageSize)
        products = try container.decodeIfPresent([WorldProductDTO].self, forKey: .products)
    }
}

struct WorldProductEnvelopeDTO: Decodable, Sendable {
    let status: Int?
    let product: WorldProductDTO?

    enum CodingKeys: String, CodingKey {
        case status, product
    }

    init(status: Int?, product: WorldProductDTO?) {
        self.status = status
        self.product = product
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = FlexibleJSON.int(container, forKey: .status)
        product = try container.decodeIfPresent(WorldProductDTO.self, forKey: .product)
    }
}

struct WorldProductDTO: Decodable, Sendable {
    let code: String?
    let productName: String?
    let brands: String?
    let imageURL: String?
    let imageFrontURL: String?
    let imageFrontSmallURL: String?
    let nutriments: WorldNutrimentDTO?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case imageURL = "image_url"
        case imageFrontURL = "image_front_url"
        case imageFrontSmallURL = "image_front_small_url"
        case nutriments
    }
}

/// Mirrors Open Food Facts nutriment JSON. Identity mapping ignores these values.
struct WorldNutrimentDTO: Decodable, Sendable {
    let energyKcal100g: Double?
    let energyKj100g: Double?

    init(energyKcal100g: Double?, energyKj100g: Double?) {
        self.energyKcal100g = energyKcal100g
        self.energyKj100g = energyKj100g
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NutrimentKey.self)
        energyKcal100g = FlexibleJSON.double(container, .energyKcal100g)
            ?? FlexibleJSON.double(container, .energyKcalAlt)
        energyKj100g = FlexibleJSON.double(container, .energyKj100g)
            ?? FlexibleJSON.double(container, .energy100g)
    }

    private enum NutrimentKey: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case energyKcalAlt = "energy_kcal_100g"
        case energy100g = "energy_100g"
        case energyKj100g = "energy-kj_100g"
    }
}

enum TinIdentityMap {
    static func make(_ dto: WorldProductDTO) -> TinIdentity? {
        let code = dto.code?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !code.isEmpty else { return nil }
        let trimmedName = dto.productName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedBrand = dto.brands?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = trimmedName.isEmpty ? (trimmedBrand.isEmpty ? code : trimmedBrand) : trimmedName
        let image = firstNonEmpty(dto.imageURL, dto.imageFrontURL, dto.imageFrontSmallURL)
        return TinIdentity(
            barcode: code,
            name: name,
            brand: trimmedBrand.isEmpty ? nil : trimmedBrand,
            imageURL: image
        )
    }

    private static func firstNonEmpty(_ values: String?...) -> String? {
        for value in values {
            guard let value else { continue }
            if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }
        return nil
    }
}

enum FlexibleJSON {
    static func int<Key: CodingKey>(_ container: KeyedDecodingContainer<Key>, forKey key: Key) -> Int? {
        if let value = try? container.decode(Int.self, forKey: key) { return value }
        if let value = try? container.decode(String.self, forKey: key) { return Int(value) }
        if let value = try? container.decode(Double.self, forKey: key) { return Int(value) }
        return nil
    }

    static func double<Key: CodingKey>(_ container: KeyedDecodingContainer<Key>, _ key: Key) -> Double? {
        if let value = try? container.decode(Double.self, forKey: key) { return value }
        if let value = try? container.decode(Int.self, forKey: key) { return Double(value) }
        if let text = try? container.decode(String.self, forKey: key) { return Double(text) }
        return nil
    }
}
