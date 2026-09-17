import Foundation

/// Digit runs 8–14 from camera, typed, or QR/URL payloads. 12-digit UPC-A gets a leading 0.
enum TinCodeHarvest {
    static func candidates(from payload: String) -> [String] {
        let matches = payload.matches(of: /[0-9]{8,14}/)
        var seen = Set<String>()
        var result: [String] = []
        func append(_ code: String) {
            guard seen.insert(code).inserted else { return }
            result.append(code)
        }
        for match in matches {
            let run = String(match.output)
            if run.count == 12 {
                append("0" + run)
            }
            append(run)
        }
        return result
    }
}
