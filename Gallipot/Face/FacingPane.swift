import SwiftUI

/// Twist screen. Face-then-pull explained as a stillroom rule, not an axis title.
struct FacingPane: View {
    @ScaledMetric(relativeTo: .body) private var displaySize = StillroomMeasure.displayPoints

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
                Image("glp_TwistHero")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: StillroomMeasure.space(35))
                    .accessibilityHidden(true)

                Text("Older pack first")
                    .font(StillroomType.title)
                    .foregroundStyle(StillroomPaint.ink)

                Text("The soonest date sits in front. A newer pack never takes that row while an older one remains.")
                    .font(StillroomType.body)
                    .foregroundStyle(StillroomPaint.ink)

                HStack(alignment: .firstTextBaseline, spacing: StillroomMeasure.space(2)) {
                    Text("1")
                        .font(StillroomType.display(displaySize))
                        .foregroundStyle(StillroomPaint.accent)
                        .monospacedDigit()
                    VStack(alignment: .leading, spacing: 0) {
                        Text("FACE")
                            .font(StillroomType.micro)
                            .foregroundStyle(StillroomPaint.muted)
                            .tracking(1.6)
                        Text("Pull peels that pack. Qty 0 steps the next date forward.")
                            .font(StillroomType.body)
                            .foregroundStyle(StillroomPaint.ink)
                    }
                }
                .padding(StillroomMeasure.space(2))
                .frame(maxWidth: .infinity, alignment: .leading)
                .stillroomCard()

                VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
                    compactRule(label: "SCAN", line: "A tin lands with a date. Same code and same day stack qty.")
                    compactRule(label: "MIDNIGHT", line: "A past best before folds to Spent until Cull.")
                    compactRule(label: "UNDO", line: "Undo peels the last pull or the last tin.")
                }
                .padding(StillroomMeasure.space(2))
                .frame(maxWidth: .infinity, alignment: .leading)
                .stillroomCard()
            }
            .padding(StillroomMeasure.space(2))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(StillroomPaint.background.ignoresSafeArea())
        .contentMargins(.bottom, StillroomMeasure.space(3), for: .scrollContent)
        .navigationTitle("How Pull works")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func compactRule(label: String, line: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(StillroomType.micro)
                .foregroundStyle(StillroomPaint.muted)
                .tracking(1.6)
            Text(line)
                .font(StillroomType.body)
                .foregroundStyle(StillroomPaint.ink)
                .padding(.top, StillroomMeasure.space(1))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
