import SwiftUI

/// Variance row on the UseSoon rail. Thinner than the hero. Pull stays available.
struct FaceThinRow: View {
    var face: Face
    var behindLots: [Lot]
    var pull: () -> Void
    var openBay: () -> Void
    @Environment(StillroomSession.self) private var session

    var body: some View {
        HStack(spacing: StillroomMeasure.space(2)) {
            Button(action: openBay) {
                VStack(alignment: .leading, spacing: StillroomMeasure.space(1)) {
                    HStack(spacing: StillroomMeasure.space(2)) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(face.bay.name)
                                .font(StillroomType.headline)
                                .foregroundStyle(StillroomPaint.ink)
                                .lineLimit(1)
                            Text(FaceInk.bestBefore(face.lot.bestBeforeDaykey))
                                .font(StillroomType.caption)
                                .foregroundStyle(StillroomPaint.muted)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(FaceInk.daysLeft(face.daysLeft))
                                .font(StillroomType.headline)
                                .foregroundStyle(StillroomPaint.ink)
                                .monospacedDigit()
                            Text("DAYS")
                                .font(StillroomType.micro)
                                .foregroundStyle(StillroomPaint.muted)
                                .tracking(1.2)
                        }
                    }
                    if !behindLots.isEmpty {
                        ForEach(behindLots) { lot in
                            HStack(spacing: StillroomMeasure.space(1)) {
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
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: StillroomMeasure.hit, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(StillroomPressStyle())
            .accessibilityLabel("Open \(face.bay.name)")

            Button("Pull", action: pull)
                .buttonStyle(StillroomChipFillStyle())
                .disabled(session.verbBusy)
                .accessibilityLabel("Pull \(face.bay.name)")
        }
        .padding(.horizontal, StillroomMeasure.space(2))
        .padding(.vertical, StillroomMeasure.space(1))
        .stillroomCard()
    }
}

