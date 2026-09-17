import SwiftUI

/// Full-page walkthrough. Skip writes the completion flag. Continue is always full width.
struct OnboardingStack: View {
    @Environment(StillroomSession.self) private var session
    @State private var page = 0

    private let pages: [(art: String, headline: String, line: String)] = [
        (
            "glp_Onboarding1",
            "Scan a tin",
            "Set the best before, and the older pack sits in front."
        ),
        (
            "glp_Onboarding2",
            "Pull the front pack",
            "Pull peels that tin. A newer pack stays behind until that one is gone."
        ),
        (
            "glp_Onboarding3",
            "Spent at midnight",
            "Past dates fold to Spent. Cull them from Pantry."
        ),
        (
            "glp_TwistHero",
            "Older pack first",
            "Qty stacks on the same day. Home is Use Soon, not a calorie log."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: StillroomMeasure.space(1)) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? StillroomPaint.accent : StillroomPaint.muted.opacity(0.35))
                        .frame(
                            width: index == page ? StillroomMeasure.space(3) : StillroomMeasure.space(1),
                            height: StillroomMeasure.space(1)
                        )
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, StillroomMeasure.space(2))

            Button("Continue") {
                advance()
            }
            .buttonStyle(StillroomFillStyle())
            .padding(.horizontal, StillroomMeasure.space(2))

            Button("Skip") {
                Task { await session.finishOnboarding() }
            }
            .buttonStyle(StillroomQuietStyle())
            .padding(.horizontal, StillroomMeasure.space(2))
            .padding(.top, StillroomMeasure.space(1))
            .padding(.bottom, StillroomMeasure.space(2))
        }
        .background(StillroomPaint.background.ignoresSafeArea())
    }

    private func pageView(_ item: (art: String, headline: String, line: String)) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: StillroomMeasure.space(2))
            Image(item.art)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: StillroomMeasure.space(45))
                .accessibilityHidden(true)
            Text(item.headline)
                .font(StillroomType.title)
                .foregroundStyle(StillroomPaint.ink)
                .padding(.top, StillroomMeasure.space(3))
            Text(item.line)
                .font(StillroomType.body)
                .foregroundStyle(StillroomPaint.muted)
                .padding(.top, StillroomMeasure.space(1))
            Spacer(minLength: StillroomMeasure.space(2))
        }
        .padding(.horizontal, StillroomMeasure.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func advance() {
        if page >= pages.count - 1 {
            Task { await session.finishOnboarding() }
        } else {
            page += 1
        }
    }
}
