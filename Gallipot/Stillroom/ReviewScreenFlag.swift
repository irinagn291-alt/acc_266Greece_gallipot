import Foundation

/// Launch argument `-ReviewScreen today|log|goals` read once after onboarding.
/// Extra cover slugs open this app's own screens instead of falling through to home.
enum ReviewScreenFlag: String, Equatable, Sendable {
    case today
    case log
    case goals
    case scan
    case facing
    case bay

    static func fromProcessInfo() -> ReviewScreenFlag? {
        parse(arguments: ProcessInfo.processInfo.arguments)
    }

    static func isPresent(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        arguments.contains("-ReviewScreen")
    }

    static func parse(arguments: [String]) -> ReviewScreenFlag? {
        guard let index = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = index + 1
        guard next < arguments.count else { return nil }
        switch arguments[next].lowercased() {
        case Self.today.rawValue, "usesoon", "use-soon", "home":
            return .today
        case Self.log.rawValue, "pantry":
            return .log
        case Self.goals.rawValue, "settings":
            return .goals
        case Self.scan.rawValue, "capture":
            return .scan
        case Self.facing.rawValue:
            return .facing
        case Self.bay.rawValue:
            return .bay
        default:
            return nil
        }
    }

    static func consume(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        onboarded: Bool,
        consumed: inout Bool
    ) -> ReviewScreenFlag? {
        guard onboarded, !consumed else { return nil }
        consumed = true
        return parse(arguments: arguments)
    }
}
