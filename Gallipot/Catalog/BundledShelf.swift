import Foundation

struct BundledShelf: Sendable {
    var tins: [TinIdentity]

    static let baked: [TinIdentity] = [
        TinIdentity(barcode: "2034567890128", name: "Rolled oats", brand: "Mill", imageURL: nil),
        TinIdentity(barcode: "2034567890135", name: "Tomato paste", brand: "Kettle", imageURL: nil),
        TinIdentity(barcode: "2034567890142", name: "Chickpeas", brand: "Tin", imageURL: nil),
        TinIdentity(barcode: "2034567890159", name: "Black tea", brand: "Caddy", imageURL: nil),
        TinIdentity(barcode: "2034567890166", name: "White rice", brand: "Bin", imageURL: nil),
        TinIdentity(barcode: "2034567890173", name: "Olive oil", brand: "Cruet", imageURL: nil),
        TinIdentity(barcode: "2034567890180", name: "Red lentils", brand: "Sack", imageURL: nil),
        TinIdentity(barcode: "2034567890197", name: "Plain flour", brand: "Mill", imageURL: nil),
        TinIdentity(barcode: "2034567890203", name: "Chopped tomatoes", brand: "Kettle", imageURL: nil),
        TinIdentity(barcode: "2034567890210", name: "Dried pasta", brand: "Bin", imageURL: nil),
    ]

    static func load(from bundle: Bundle) -> BundledShelf {
        guard let url = bundle.url(forResource: "bundled_shelf", withExtension: "json") else {
            return BundledShelf(tins: baked)
        }
        do {
            let data = try Data(contentsOf: url)
            let file = try JSONDecoder().decode(ShelfFile.self, from: data)
            let tins = file.tins.map(\.identity)
            return BundledShelf(tins: tins.isEmpty ? baked : tins)
        } catch {
            return BundledShelf(tins: baked)
        }
    }

    func identity(code: String) -> TinIdentity? {
        tins.first { $0.barcode == code }
    }

    func matching(_ terms: String) -> [TinIdentity] {
        let needle = terms.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return tins }
        return tins.filter { tin in
            tin.name.lowercased().contains(needle)
                || (tin.brand?.lowercased().contains(needle) ?? false)
                || tin.barcode.contains(needle)
        }
    }
}

private struct ShelfFile: Decodable {
    let tins: [ShelfTin]
}

private struct ShelfTin: Decodable {
    let barcode: String
    let name: String
    let brand: String?
    let imageURL: String?

    var identity: TinIdentity {
        TinIdentity(barcode: barcode, name: name, brand: brand, imageURL: imageURL)
    }
}
