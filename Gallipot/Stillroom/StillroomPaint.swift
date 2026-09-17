import SwiftUI

/// Named colours in Assets.xcassets. Views use these tokens, never a raw hex.
/// background #FBF6F4, surface #FEFEFD, ink #392218, accent #C15425, muted #8B695B
enum StillroomPaint {
    static var background: Color { Color("stillroomBackground") }
    static var surface: Color { Color("stillroomSurface") }
    static var ink: Color { Color("stillroomInk") }
    static var accent: Color { Color("stillroomAccent") }
    static var muted: Color { Color("stillroomMuted") }
}
