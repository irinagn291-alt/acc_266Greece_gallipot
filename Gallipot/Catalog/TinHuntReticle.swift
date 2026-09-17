import SwiftUI

/// Scanner reticle drawn in SwiftUI. Not a generated asset.
struct TinHuntReticle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let arm = min(rect.width, rect.height) * 0.14
        let points: [(CGPoint, CGPoint, CGPoint)] = [
            (CGPoint(x: rect.minX, y: rect.minY + arm), CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.minX + arm, y: rect.minY)),
            (CGPoint(x: rect.maxX - arm, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY + arm)),
            (CGPoint(x: rect.maxX, y: rect.maxY - arm), CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.maxX - arm, y: rect.maxY)),
            (CGPoint(x: rect.minX + arm, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY - arm)),
        ]
        for corner in points {
            path.move(to: corner.0)
            path.addLine(to: corner.1)
            path.addLine(to: corner.2)
        }
        return path
    }
}
