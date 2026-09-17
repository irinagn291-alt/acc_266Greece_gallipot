import SwiftUI

/// Bay detail from Pantry or a deep link. Live lots stack behind the Face. Later lots cannot be pulled.
struct BayPane: View {
    var bayID: UUID
    @Environment(StillroomSession.self) private var session

    private var stack: BayStack? {
        session.stacks.first { $0.bay.id == bayID }
    }

    var body: some View {
        Group {
            if let stack {
                content(stack)
            } else {
                StillroomFaultCutout(
                    headline: "This tin is gone.",
                    line: "It was culled or never landed.",
                    retry: { session.presentPantry() }
                )
            }
        }
        .background(StillroomPaint.background.ignoresSafeArea())
        .navigationTitle(stack?.bay.name ?? "Bay")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(_ stack: BayStack) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
                if let face = stack.face {
                    FaceHeroCard(face: face, behindLots: Array(stack.liveLots.dropFirst())) {
                        Task { await session.pullFace(stack.bay.id) }
                    }
                } else {
                    Text("No pack in front. Spent dates wait for Cull.")
                        .font(StillroomType.body)
                        .foregroundStyle(StillroomPaint.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(StillroomMeasure.space(2))
                        .stillroomCard()
                }

                if !stack.liveLots.isEmpty {
                    readoutStack(title: "OPEN", lots: stack.liveLots, faceID: stack.face?.lot.id)
                }

                if !stack.spentLots.isEmpty {
                    readoutStack(title: "SPENT", lots: stack.spentLots, faceID: nil)
                }
            }
            .padding(StillroomMeasure.space(2))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentMargins(.bottom, StillroomMeasure.space(3), for: .scrollContent)
    }

    private func readoutStack(title: String, lots: [Lot], faceID: UUID?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(StillroomType.micro)
                .foregroundStyle(StillroomPaint.muted)
                .tracking(1.4)
                .padding(.bottom, StillroomMeasure.space(1))
            VStack(spacing: 0) {
                ForEach(Array(lots.enumerated()), id: \.element.id) { index, lot in
                    if index > 0 {
                        Rectangle()
                            .fill(StillroomPaint.muted.opacity(0.45))
                            .frame(height: StillroomMeasure.hairline)
                    }
                    lotReadout(lot, isFace: lot.id == faceID)
                }
            }
            .stillroomCard()
        }
    }

    private func lotReadout(_ lot: Lot, isFace: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: StillroomMeasure.space(2)) {
            if isFace {
                Text("FACE")
                    .font(StillroomType.micro)
                    .foregroundStyle(StillroomPaint.muted)
                    .tracking(1.3)
            }
            Text(FaceInk.bestBefore(lot.bestBeforeDaykey))
                .font(StillroomType.caption)
                .foregroundStyle(isFace ? StillroomPaint.ink : StillroomPaint.muted)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text("QTY")
                .font(StillroomType.micro)
                .foregroundStyle(StillroomPaint.muted)
                .tracking(1.3)
            Text(FaceInk.quantity(lot.quantity))
                .font(StillroomType.caption)
                .foregroundStyle(StillroomPaint.ink)
                .monospacedDigit()
                .lineLimit(1)
        }
        .padding(.horizontal, StillroomMeasure.space(2))
        .padding(.vertical, StillroomMeasure.space(1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(readoutLabel(lot, isFace: isFace))
    }

    private func readoutLabel(_ lot: Lot, isFace: Bool) -> String {
        let date = FaceInk.bestBefore(lot.bestBeforeDaykey)
        let qty = FaceInk.quantity(lot.quantity)
        if isFace {
            return "FACE, \(date), QTY \(qty). Pull is on the pack above."
        }
        return "\(date), QTY \(qty). Stacked. Not pullable."
    }
}
