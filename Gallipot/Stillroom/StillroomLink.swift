import Foundation

/// Logical places. ReviewScreen today|log|goals map here. They are not tab-bar items.
enum StillroomTab: String, Hashable, Sendable {
    case useSoon
    case pantry
    case settings
}

/// Pushed places on the stillroom stack. Home stays the UseSoon root. Scan stays a sheet.
enum StillroomPlace: Hashable, Sendable {
    case pantry
    case settings
    case facing
    case bay(UUID)
}

enum StillroomLink: Equatable, Sendable {
    case useSoon
    case scan
    case pantry
    case bay(UUID)
    case settings

    static func parse(_ url: URL) -> StillroomLink? {
        let scheme = url.scheme?.lowercased() ?? ""
        let host = url.host?.lowercased() ?? ""
        let parts = url.pathComponents.filter { $0 != "/" }

        if scheme == "gallipot" {
            let token = host.isEmpty ? (parts.first?.lowercased() ?? "") : host
            let rest = host.isEmpty ? Array(parts.dropFirst()) : parts
            return interpret(token: token, rest: rest)
        }
        if scheme == "https" || scheme == "http" {
            guard host == "gallipot-bay.pro" || host == "www.gallipot-bay.pro" else { return nil }
            let token = parts.first?.lowercased() ?? ""
            let rest = Array(parts.dropFirst())
            return interpret(token: token, rest: rest)
        }
        return nil
    }

    private static func interpret(token: String, rest: [String]) -> StillroomLink? {
        switch token {
        case "", "usesoon", "use-soon", "today":
            return .useSoon
        case "scan":
            return .scan
        case "settings", "goals":
            return .settings
        case "pantry", "log":
            if let raw = rest.first, let id = UUID(uuidString: raw) {
                return .bay(id)
            }
            return .pantry
        case "bay":
            if let raw = rest.first, let id = UUID(uuidString: raw) {
                return .bay(id)
            }
            return .pantry
        default:
            return nil
        }
    }

    var tab: StillroomTab {
        switch self {
        case .useSoon, .scan: return .useSoon
        case .pantry, .bay: return .pantry
        case .settings: return .settings
        }
    }

    static func tab(for flag: ReviewScreenFlag) -> StillroomTab {
        switch flag {
        case .today, .scan, .facing: return .useSoon
        case .log, .bay: return .pantry
        case .goals: return .settings
        }
    }
}

/// Product URLs. Literals are fixed; they are not network-derived.
enum StillroomURL {
    static let openFoodFacts = URL(string: "https://world.openfoodfacts.org")!
    static let contact = URL(string: "https://gallipot-bay.pro/contact-us")!
}
