import SwiftUI

/// Hero Face on UseSoon. Display-size days-left, then Pull. Not a stat card quartet.
struct FaceHeroCard: View {
    var face: Face
    var behindLots: [Lot]
    var pull: () -> Void
    @Environment(StillroomSession.self) private var session
    @Environment(\.horizontalSizeClass) private var sizeClass
    @ScaledMetric(relativeTo: .body) private var displaySize = StillroomMeasure.displayPoints

    var body: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
            ZStack(alignment: .bottomLeading) {
                Image("glp_CardBackdrop")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, minHeight: artMin, maxHeight: artMax)
                    .clipped()
                    .accessibilityHidden(true)
                LinearGradient(
                    colors: [StillroomPaint.surface.opacity(0.15), StillroomPaint.surface.opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                VStack(alignment: .leading, spacing: StillroomMeasure.space(1)) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("FACE")
                            .font(StillroomType.micro)
                            .foregroundStyle(StillroomPaint.muted)
                            .textCase(.uppercase)
                            .tracking(1.4)
                        Spacer()
                        Text(face.bay.brand ?? face.bay.barcode)
                            .font(StillroomType.micro)
                            .foregroundStyle(StillroomPaint.muted)
                            .lineLimit(1)
                    }
                    Text(face.bay.name)
                        .font(StillroomType.title)
                        .foregroundStyle(StillroomPaint.ink)
                        .lineLimit(1)
                }
                .padding(StillroomMeasure.space(2))
            }
            .frame(maxWidth: .infinity)
            .clipped()

            HStack(alignment: .firstTextBaseline, spacing: StillroomMeasure.space(2)) {
                Text(FaceInk.daysLeft(face.daysLeft))
                    .font(StillroomType.display(displaySize))
                    .foregroundStyle(StillroomPaint.accent)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                VStack(alignment: .leading, spacing: 0) {
                    Text("DAYS LEFT")
                        .font(StillroomType.micro)
                        .foregroundStyle(StillroomPaint.muted)
                        .tracking(1.6)
                    Text(FaceInk.bestBefore(face.lot.bestBeforeDaykey))
                        .font(StillroomType.caption)
                        .foregroundStyle(StillroomPaint.ink)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: StillroomMeasure.space(3)) {
                metric(label: "QTY", value: FaceInk.quantity(face.lot.quantity))
                metric(label: "BEHIND", value: FaceInk.integer(behindLots.count))
                Spacer(minLength: 0)
            }

            if !behindLots.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(behindLots) { lot in
                        HStack(alignment: .firstTextBaseline, spacing: StillroomMeasure.space(1)) {
                            Text("BEHIND")
                                .font(StillroomType.micro)
                                .foregroundStyle(StillroomPaint.muted)
                                .tracking(1.2)
                            Text(FaceInk.bestBefore(lot.bestBeforeDaykey))
                                .font(StillroomType.caption)
                                .foregroundStyle(StillroomPaint.ink)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Text("QTY")
                                .font(StillroomType.micro)
                                .foregroundStyle(StillroomPaint.muted)
                                .tracking(1.2)
                            Text(FaceInk.quantity(lot.quantity))
                                .font(StillroomType.caption)
                                .foregroundStyle(StillroomPaint.ink)
                                .monospacedDigit()
                        }
                        .frame(minHeight: StillroomMeasure.hit / 2)
                    }
                }
            }

            PullFaceControl(enabled: !session.verbBusy, action: pull)
        }
        .padding(StillroomMeasure.space(2))
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .stillroomCard()
    }

    private var artMin: CGFloat {
        sizeClass == .regular ? StillroomMeasure.space(12) : StillroomMeasure.space(21)
    }

    private var artMax: CGFloat {
        sizeClass == .regular ? StillroomMeasure.space(16) : StillroomMeasure.space(25)
    }

    private func metric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(StillroomType.micro)
                .foregroundStyle(StillroomPaint.muted)
                .tracking(1.4)
            Text(value)
                .font(StillroomType.headline)
                .foregroundStyle(StillroomPaint.ink)
                .monospacedDigit()
        }
    }
}
