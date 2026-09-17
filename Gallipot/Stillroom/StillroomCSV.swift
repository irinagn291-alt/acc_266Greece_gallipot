import Foundation

enum StillroomCSV {
    static func render(_ document: StillroomDocument) -> String {
        var lines: [String] = ["barcode,name,brand,daykey,qty,state"]
        func row(lot: Lot, bay: Bay?, state: String) {
            let name = bay?.name ?? ""
            let brand = bay?.brand ?? ""
            lines.append(
                [
                    escape(lot.barcode),
                    escape(name),
                    escape(brand),
                    String(lot.bestBeforeDaykey),
                    String(lot.quantity),
                    state,
                ].joined(separator: ",")
            )
        }
        let bays = Dictionary(uniqueKeysWithValues: document.bays.map { ($0.id, $0) })
        for lot in document.lots {
            row(lot: lot, bay: bays[lot.bayID], state: "live")
        }
        for lot in document.spent {
            row(lot: lot, bay: bays[lot.bayID], state: "spent")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func write(_ document: StillroomDocument, to url: URL, fileManager: FileManager) throws {
        let folder = url.deletingLastPathComponent()
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        let data = Data(render(document).utf8)
        try data.write(to: url, options: .atomic)
    }

    private static func escape(_ raw: String) -> String {
        if raw.contains(",") || raw.contains("\"") || raw.contains("\n") {
            return "\"" + raw.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return raw
    }
}
