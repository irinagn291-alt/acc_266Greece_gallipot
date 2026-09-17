import SwiftUI

/// Bordered-prominent Pull. Home verb for the Face. Artwork is a tin lid, not an SF logo.
struct PullFaceControl: View {
    var enabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: StillroomMeasure.space(1)) {
                Image("glp_ControlFace")
                    .resizable()
                    .scaledToFit()
                    .frame(width: StillroomMeasure.space(4), height: StillroomMeasure.space(4))
                    .accessibilityHidden(true)
                Text("Pull")
            }
            .frame(maxWidth: .infinity, minHeight: StillroomMeasure.hit)
            .contentShape(Rectangle())
        }
        .buttonStyle(StillroomFillStyle())
        .disabled(!enabled)
        .accessibilityLabel("Pull the facing tin")
    }
}
