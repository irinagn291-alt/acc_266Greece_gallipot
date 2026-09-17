import SwiftUI

/// Spacing, radii, and elevation for stillroom chrome. Views never pick a raw pt.
enum StillroomMeasure {
    static let unit: CGFloat = 8

    static func space(_ steps: Int) -> CGFloat {
        unit * CGFloat(steps)
    }

    static var radius: CGFloat { 12 }
    static var chipRadius: CGFloat { 8 }
    static var hairline: CGFloat { 1 }
    static var hit: CGFloat { 44 }
    static var pressScale: CGFloat { 0.97 }
    static var snap: Double { 0.16 }
    static var sheetSnap: Double { 0.22 }
    static var displayPoints: CGFloat { 43 }
    static var spinnerGate: Duration { .milliseconds(150) }
    static var huntCooldown: TimeInterval { 1.75 }
}
