import SwiftUI

/// Root chrome. Onboarding, then stillroom destinations. ReviewScreen is read after onboarding.
struct ContentView: View {
    @State private var session = StillroomSession.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if let fault = session.bootFault, !session.isReady {
                StillroomFaultCutout(
                    headline: "Gallipot did not open.",
                    line: fault,
                    retry: {
                        Task { await session.retryBoot() }
                    }
                )
            } else if !session.isReady {
                StillroomPaint.background
                    .ignoresSafeArea()
                    .overlay {
                        Image("glp_Splash")
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                            .accessibilityHidden(true)
                    }
            } else if session.showOnboarding {
                OnboardingStack()
            } else {
                StillroomChrome()
                    .onAppear { session.applyReviewIfNeeded() }
            }
        }
        .environment(session)
        .background(StillroomPaint.background.ignoresSafeArea())
        .tint(StillroomPaint.accent)
        .preferredColorScheme(.light)
        .task { await session.boot() }
        .onOpenURL { session.open(url: $0) }
        .onChange(of: scenePhase) { _, phase in
            Task { await session.handle(phase: phase) }
        }
    }
}

#Preview {
    ContentView()
        .environment(StillroomSession.shared)
}
