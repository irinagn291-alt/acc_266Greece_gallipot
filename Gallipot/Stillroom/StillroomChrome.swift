import SwiftUI

/// Stack chrome. UseSoon is home. Pantry, Settings, Facing, and Bay push. Scan is a sheet on phone, a page on pad.
struct StillroomChrome: View {
    @Environment(StillroomSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        @Bindable var session = session
        NavigationStack(path: $session.stackPath) {
            UseSoonRail()
                .navigationDestination(for: StillroomPlace.self) { place in
                    switch place {
                    case .pantry:
                        PantryPane()
                    case .settings:
                        SettingsDesk()
                    case .facing:
                        FacingPane()
                    case .bay(let id):
                        BayPane(bayID: id)
                    }
                }
        }
        .background(StillroomPaint.background.ignoresSafeArea())
        .tint(StillroomPaint.accent)
        .sheet(isPresented: compactScan($session.scanPresented)) {
            ScanView()
                .presentationCornerRadius(StillroomMeasure.radius)
                .presentationBackground(StillroomPaint.surface)
                .stillroomSheetLift()
        }
        .fullScreenCover(isPresented: pageScan($session.scanPresented)) {
            ScanView()
        }
        .overlay(alignment: .center) {
            if session.commitFlash {
                Image("glp_SuccessMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: StillroomMeasure.space(12), height: StillroomMeasure.space(12))
                    .accessibilityHidden(true)
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: StillroomMeasure.snap), value: session.commitFlash)
        .onChange(of: session.stackPath) { _, path in
            session.notePath(path)
        }
    }

    private func compactScan(_ presented: Binding<Bool>) -> Binding<Bool> {
        Binding(
            get: { presented.wrappedValue && sizeClass != .regular },
            set: { presented.wrappedValue = $0 }
        )
    }

    private func pageScan(_ presented: Binding<Bool>) -> Binding<Bool> {
        Binding(
            get: { presented.wrappedValue && sizeClass == .regular },
            set: { presented.wrappedValue = $0 }
        )
    }
}
