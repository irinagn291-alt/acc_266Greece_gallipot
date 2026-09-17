import SwiftUI
import UIKit

/// Press scale, hairline fill, and the commit haptic. One motion language.
enum StillroomCommit {
    @MainActor
    static func pulse() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct StillroomFillStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(StillroomType.headline)
            .foregroundStyle(StillroomPaint.surface)
            .frame(maxWidth: .infinity, minHeight: StillroomMeasure.hit)
            .padding(.horizontal, StillroomMeasure.space(2))
            .background(isEnabled ? StillroomPaint.accent : StillroomPaint.muted)
            .clipShape(RoundedRectangle(cornerRadius: StillroomMeasure.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: StillroomMeasure.radius, style: .continuous)
                    .stroke(StillroomPaint.ink.opacity(isEnabled ? 0.18 : 0.08), lineWidth: StillroomMeasure.hairline)
            )
            .scaleEffect(scale(configuration.isPressed))
            .opacity(reduceMotion && configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: StillroomMeasure.snap), value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: StillroomMeasure.radius, style: .continuous))
    }

    private func scale(_ pressed: Bool) -> CGFloat {
        if reduceMotion { return 1 }
        return pressed ? StillroomMeasure.pressScale : 1
    }
}

struct StillroomQuietStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(StillroomType.headline)
            .foregroundStyle(isEnabled ? StillroomPaint.ink : StillroomPaint.muted)
            .frame(maxWidth: .infinity, minHeight: StillroomMeasure.hit)
            .padding(.horizontal, StillroomMeasure.space(2))
            .background(StillroomPaint.surface)
            .clipShape(RoundedRectangle(cornerRadius: StillroomMeasure.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: StillroomMeasure.radius, style: .continuous)
                    .stroke(StillroomPaint.muted.opacity(isEnabled ? 0.55 : 0.3), lineWidth: StillroomMeasure.hairline)
            )
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? StillroomMeasure.pressScale : 1))
            .opacity(reduceMotion && configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: StillroomMeasure.snap), value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: StillroomMeasure.radius, style: .continuous))
    }
}

struct StillroomChipFillStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(StillroomType.headline)
            .foregroundStyle(StillroomPaint.surface)
            .padding(.horizontal, StillroomMeasure.space(2))
            .frame(minWidth: StillroomMeasure.hit, minHeight: StillroomMeasure.hit)
            .background(isEnabled ? StillroomPaint.accent : StillroomPaint.muted)
            .clipShape(RoundedRectangle(cornerRadius: StillroomMeasure.chipRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: StillroomMeasure.chipRadius, style: .continuous)
                    .stroke(StillroomPaint.ink.opacity(isEnabled ? 0.18 : 0.08), lineWidth: StillroomMeasure.hairline)
            )
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? StillroomMeasure.pressScale : 1))
            .opacity(reduceMotion && configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: StillroomMeasure.snap), value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: StillroomMeasure.chipRadius, style: .continuous))
    }
}

struct StillroomPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? StillroomMeasure.pressScale : 1))
            .opacity(reduceMotion && configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: StillroomMeasure.snap), value: configuration.isPressed)
    }
}

struct StillroomSheetLift: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lifted = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(reduceMotion ? 1 : (lifted ? 1 : 0.96))
            .opacity(lifted ? 1 : 0)
            .onAppear {
                if reduceMotion {
                    lifted = true
                } else {
                    withAnimation(.easeOut(duration: StillroomMeasure.sheetSnap)) {
                        lifted = true
                    }
                }
            }
    }
}

struct StillroomDestroyStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(StillroomType.headline)
            .foregroundStyle(StillroomPaint.ink)
            .frame(maxWidth: .infinity, minHeight: StillroomMeasure.hit)
            .padding(.horizontal, StillroomMeasure.space(2))
            .background(StillroomPaint.surface)
            .clipShape(RoundedRectangle(cornerRadius: StillroomMeasure.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: StillroomMeasure.radius, style: .continuous)
                    .stroke(StillroomPaint.ink.opacity(isEnabled ? 0.45 : 0.2), lineWidth: StillroomMeasure.hairline)
            )
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? StillroomMeasure.pressScale : 1))
            .opacity(reduceMotion && configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: StillroomMeasure.snap), value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: StillroomMeasure.radius, style: .continuous))
    }
}

extension View {
    func stillroomCard() -> some View {
        background(StillroomPaint.surface)
            .clipShape(RoundedRectangle(cornerRadius: StillroomMeasure.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: StillroomMeasure.radius, style: .continuous)
                    .stroke(StillroomPaint.muted.opacity(0.45), lineWidth: StillroomMeasure.hairline)
            )
    }

    func stillroomChip() -> some View {
        background(StillroomPaint.surface)
            .clipShape(RoundedRectangle(cornerRadius: StillroomMeasure.chipRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: StillroomMeasure.chipRadius, style: .continuous)
                    .stroke(StillroomPaint.muted.opacity(0.45), lineWidth: StillroomMeasure.hairline)
            )
    }

    func stillroomSheetLift() -> some View {
        modifier(StillroomSheetLift())
    }

    func stillroomFillCanvas() -> some View {
        modifier(StillroomFillCanvas())
    }
}

/// iPad boards fill the proposed height with this screen's mechanic, then scroll if type is large.
private struct StillroomFillCanvas: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { geo in
            ScrollView {
                content
                    .frame(minWidth: geo.size.width, minHeight: geo.size.height, alignment: .topLeading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
