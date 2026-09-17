import AppIntents

/// App Intents open UseSoon, Scan, a Bay, or Settings. They never mutate the stillroom document.
struct OpenUseSoonIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Use Soon" }
    static var description: IntentDescription { "Open Use Soon." }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await StillroomSession.shared.open(.useSoon)
        return .result()
    }
}

struct OpenScanIntent: AppIntent {
    static var title: LocalizedStringResource { "Scan a tin" }
    static var description: IntentDescription { "Open scan and best-before on Use Soon." }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await StillroomSession.shared.open(.scan)
        return .result()
    }
}

struct OpenPantryIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Pantry" }
    static var description: IntentDescription { "Open stacked dates behind each tin." }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await StillroomSession.shared.open(.pantry)
        return .result()
    }
}

struct OpenBayIntent: AppIntent {
    static var title: LocalizedStringResource { "Open a tin" }
    static var description: IntentDescription { "Open a stored tin by name." }
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Tin")
    var name: String

    func perform() async throws -> some IntentResult {
        await StillroomSession.shared.openBay(named: name)
        return .result()
    }
}

struct OpenSettingsIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Settings" }
    static var description: IntentDescription { "Open CSV export, sources, and reset." }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await StillroomSession.shared.open(.settings)
        return .result()
    }
}

struct GallipotShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenUseSoonIntent(),
            phrases: [
                "Open Use Soon in \(.applicationName)",
                "Show facing tins in \(.applicationName)",
            ],
            shortTitle: "Use Soon",
            systemImageName: "clock"
        )
        AppShortcut(
            intent: OpenScanIntent(),
            phrases: [
                "Scan a tin in \(.applicationName)",
            ],
            shortTitle: "Scan",
            systemImageName: "barcode.viewfinder"
        )
        AppShortcut(
            intent: OpenPantryIntent(),
            phrases: [
                "Open Pantry in \(.applicationName)",
            ],
            shortTitle: "Pantry",
            systemImageName: "square.stack.3d.up"
        )
        AppShortcut(
            intent: OpenSettingsIntent(),
            phrases: [
                "Open Settings in \(.applicationName)",
            ],
            shortTitle: "Settings",
            systemImageName: "gearshape"
        )
    }
}
