import SwiftUI

/// SF Pro via Font.system. Six steps for the metric-grid type move.
enum StillroomType {
    static var display: Font { display(StillroomMeasure.displayPoints) }

    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    static var title: Font { .system(.title, design: .default).weight(.semibold) }
    static var headline: Font { .system(.headline, design: .default) }
    static var body: Font { .system(.body, design: .default) }
    static var caption: Font { .system(.caption, design: .default).monospacedDigit() }
    static var micro: Font { .system(.caption, design: .default).weight(.semibold).monospacedDigit() }
}
