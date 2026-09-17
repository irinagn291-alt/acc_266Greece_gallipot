import Foundation

/// One Codable stillroom projection. Face and days-left are derived; Spent is folded Lots.
struct StillroomDocument: Codable, Sendable, Equatable {
    var schemaVersion: Int
    var bays: [Bay]
    var lots: [Lot]
    var pullMarks: [PullMark]
    var spent: [Lot]
    var reversals: [Reversal]
    var onboardingComplete: Bool

    static let currentSchema = 1

    static var empty: StillroomDocument {
        StillroomDocument(
            schemaVersion: currentSchema,
            bays: [],
            lots: [],
            pullMarks: [],
            spent: [],
            reversals: [],
            onboardingComplete: false
        )
    }

    init(
        schemaVersion: Int = currentSchema,
        bays: [Bay],
        lots: [Lot],
        pullMarks: [PullMark],
        spent: [Lot],
        reversals: [Reversal],
        onboardingComplete: Bool
    ) {
        self.schemaVersion = schemaVersion
        self.bays = bays
        self.lots = lots
        self.pullMarks = pullMarks
        self.spent = spent
        self.reversals = reversals
        self.onboardingComplete = onboardingComplete
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .schemaVersion)
        switch version {
        case 1:
            schemaVersion = version
            bays = try container.decode([Bay].self, forKey: .bays)
            lots = try container.decode([Lot].self, forKey: .lots)
            pullMarks = try container.decodeIfPresent([PullMark].self, forKey: .pullMarks) ?? []
            spent = try container.decodeIfPresent([Lot].self, forKey: .spent) ?? []
            reversals = try container.decodeIfPresent([Reversal].self, forKey: .reversals) ?? []
            onboardingComplete = try container.decodeIfPresent(Bool.self, forKey: .onboardingComplete) ?? false
        default:
            throw StillroomDocumentError.unsupportedSchema(version)
        }
    }
}
