import SwiftUI

/// Spent rank on Pantry until Cull. Destructive chrome, not the live Pull accent.
struct SpentCullBar: View {
    var count: Int
    var cull: () -> Void
    @State private var confirm = false

    var body: some View {
        HStack(alignment: .center, spacing: StillroomMeasure.space(2)) {
            VStack(alignment: .leading, spacing: 0) {
                Text("SPENT")
                    .font(StillroomType.micro)
                    .foregroundStyle(StillroomPaint.muted)
                    .tracking(1.4)
                Text(FaceInk.integer(count))
                    .font(StillroomType.title)
                    .foregroundStyle(StillroomPaint.ink)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
            Button("Cull") {
                confirm = true
            }
            .buttonStyle(StillroomDestroyStyle())
            .disabled(count == 0)
            .accessibilityLabel("Cull spent dates")
        }
        .padding(StillroomMeasure.space(2))
        .frame(maxWidth: .infinity, alignment: .center)
        .stillroomCard()
        .confirmationDialog("Cull spent dates. They leave this device.", isPresented: $confirm, titleVisibility: .visible) {
            Button("Cull", role: .destructive, action: cull)
            Button("Cancel", role: .cancel) {}
        }
    }
}
