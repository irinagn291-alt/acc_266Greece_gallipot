import SwiftUI

/// Routed sheet on UseSoon. Hunt (camera or local shelf) fuses into best-before on the same sheet.
struct CaptureSheet: View {
    @Environment(StillroomSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var desk: CaptureDesk?
    @FocusState private var field: CaptureField?

    var body: some View {
        NavigationStack {
            Group {
                if let desk {
                    content(desk)
                } else {
                    StillroomPaint.surface
                        .ignoresSafeArea()
                }
            }
            .background(StillroomPaint.background.ignoresSafeArea())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(minWidth: StillroomMeasure.hit, minHeight: StillroomMeasure.hit)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        field = nil
                    }
                    .font(StillroomType.headline)
                }
            }
        }
        .task {
            guard desk == nil, let porter = session.porter else { return }
            let created = CaptureDesk(porter: porter)
            desk = created
            await created.appear()
        }
        .onChange(of: scenePhase) { _, phase in
            desk?.sceneActive = phase == .active
            if phase == .active {
                desk?.refreshAccess()
            }
        }
        .onDisappear {
            desk?.sceneActive = false
        }
        .onAppear {
            desk?.sceneActive = true
        }
    }

    private var title: String {
        switch desk?.phase {
        case .fuse, .name:
            return "Best before"
        default:
            return "Scan"
        }
    }

    @ViewBuilder
    private func content(_ desk: CaptureDesk) -> some View {
        if sizeClass == .regular {
            HuntPane(desk: desk, field: $field)
        } else {
            switch desk.phase {
            case .hunt:
                HuntPane(desk: desk, field: $field)
            case .fuse, .name:
                FusePane(desk: desk, field: $field)
            }
        }
    }
}

/// Named Scan screen. Capture is a sheet on phone and a full page on pad. ReviewScreen `scan` opens this, not home.
struct ScanView: View {
    var body: some View {
        CaptureSheet()
    }
}
