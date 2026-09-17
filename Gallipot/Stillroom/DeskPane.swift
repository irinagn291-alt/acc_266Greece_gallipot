import SwiftUI

/// Settings. OFF credit is a tappable link. Reset and onboarding replay live here.
struct SettingsDesk: View {
    @Environment(StillroomSession.self) private var session
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var confirmReset = false

    var body: some View {
        Group {
            if sizeClass == .regular {
                padBoard
            } else {
                phoneStack
            }
        }
        .background(StillroomPaint.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Reset all data. Tins, dates, and pulls are removed.",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Reset all data", role: .destructive) {
                Task { await session.resetStillroom() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var phoneStack: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
                if let fault = session.deskFault {
                    exportFault(fault)
                }
                onDeviceCard
                pullOrderCard
                sourcesCard
                fileCard
                dataCard
            }
            .padding(.horizontal, StillroomMeasure.space(2))
            .padding(.top, StillroomMeasure.space(1))
            .padding(.bottom, StillroomMeasure.space(3))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var padBoard: some View {
        Grid(alignment: .topLeading, horizontalSpacing: StillroomMeasure.space(2), verticalSpacing: StillroomMeasure.space(2)) {
            if let fault = session.deskFault {
                GridRow {
                    exportFault(fault)
                        .gridCellColumns(2)
                }
            }
            GridRow(alignment: .top) {
                onDeviceCard
                pullOrderCard
            }
            GridRow(alignment: .top) {
                sourcesCard
                fileCard
            }
            GridRow(alignment: .top) {
                dataCard
                    .gridCellColumns(2)
            }
        }
        .padding(.horizontal, StillroomMeasure.space(2))
        .padding(.top, StillroomMeasure.space(1))
        .padding(.bottom, StillroomMeasure.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .stillroomFillCanvas()
    }

    private var behindCount: Int {
        max(0, session.liveCount - session.faces.count)
    }

    private var onDeviceCard: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
            Text("ON DEVICE")
                .font(StillroomType.micro)
                .foregroundStyle(StillroomPaint.muted)
                .tracking(1.4)
            if session.bayCount == 0 && session.liveCount == 0 && session.spentCount == 0 {
                Text("Nothing stored yet.")
                    .font(StillroomType.body)
                    .foregroundStyle(StillroomPaint.muted)
                    .frame(maxWidth: .infinity, minHeight: StillroomMeasure.hit, alignment: .leading)
            }
            summaryRow(label: "TINS", value: FaceInk.integer(session.bayCount))
            summaryRow(label: "OPEN", value: FaceInk.integer(session.liveCount))
            summaryRow(label: "SPENT", value: FaceInk.integer(session.spentCount))
            summaryRow(label: "BEHIND", value: FaceInk.integer(behindCount))
        }
        .padding(StillroomMeasure.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .stillroomCard()
    }

    private var pullOrderCard: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
            Text("PULL ORDER")
                .font(StillroomType.micro)
                .foregroundStyle(StillroomPaint.muted)
                .tracking(1.4)
            Button {
                session.presentFacing()
            } label: {
                Text("How Pull works")
                    .font(StillroomType.headline)
                    .frame(maxWidth: .infinity, minHeight: StillroomMeasure.hit, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(StillroomPressStyle())
            Text("Pull peels the soonest pack. Newer dates stay stacked.")
                .font(StillroomType.body)
                .foregroundStyle(StillroomPaint.ink)
            pullRule(label: "FACE", line: "The soonest date sits in front. Pull peels that pack.")
            pullRule(label: "BEHIND", line: "A later pack waits. Qty 0 steps the next date forward.")
            pullRule(label: "SPENT", line: "A past best before folds here until Cull.")
        }
        .padding(StillroomMeasure.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .stillroomCard()
    }

    private var sourcesCard: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
            Text("SOURCES")
                .font(StillroomType.micro)
                .foregroundStyle(StillroomPaint.muted)
                .tracking(1.4)
            Link(destination: StillroomURL.openFoodFacts) {
                Text("Open Food Facts")
                    .font(StillroomType.headline)
                    .frame(maxWidth: .infinity, minHeight: StillroomMeasure.hit, alignment: .leading)
                    .contentShape(Rectangle())
            }
            Text("A code names a grocery tin from Open Food Facts contributors. Names stay on this device after lookup.")
                .font(StillroomType.body)
                .foregroundStyle(StillroomPaint.ink)
            Link(destination: StillroomURL.contact) {
                Text("Contact Gallipot")
                    .font(StillroomType.headline)
                    .frame(maxWidth: .infinity, minHeight: StillroomMeasure.hit, alignment: .leading)
                    .contentShape(Rectangle())
            }
            Text("Contact Gallipot opens the support page.")
                .font(StillroomType.caption)
                .foregroundStyle(StillroomPaint.muted)
        }
        .padding(StillroomMeasure.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .stillroomCard()
    }

    private var fileCard: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
            Text("FILE")
                .font(StillroomType.micro)
                .foregroundStyle(StillroomPaint.muted)
                .tracking(1.4)
            Text("CSV lists barcode, name, brand, daykey, qty, and live or spent.")
                .font(StillroomType.body)
                .foregroundStyle(StillroomPaint.ink)
            HStack(alignment: .firstTextBaseline, spacing: StillroomMeasure.space(2)) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("OPEN ROWS")
                        .font(StillroomType.micro)
                        .foregroundStyle(StillroomPaint.muted)
                        .tracking(1.2)
                    Text(FaceInk.integer(session.liveCount))
                        .font(StillroomType.headline)
                        .foregroundStyle(StillroomPaint.ink)
                        .monospacedDigit()
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("SPENT ROWS")
                        .font(StillroomType.micro)
                        .foregroundStyle(StillroomPaint.muted)
                        .tracking(1.2)
                    Text(FaceInk.integer(session.spentCount))
                        .font(StillroomType.headline)
                        .foregroundStyle(StillroomPaint.ink)
                        .monospacedDigit()
                }
                Spacer(minLength: 0)
            }
            .frame(minHeight: StillroomMeasure.hit)
            Button {
                Task { await session.exportCSV() }
            } label: {
                Text("Export CSV")
                    .frame(maxWidth: .infinity, minHeight: StillroomMeasure.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(StillroomQuietStyle())
            if let url = session.exportedURL {
                ShareLink(item: url) {
                    Text("Share CSV")
                        .frame(maxWidth: .infinity, minHeight: StillroomMeasure.hit)
                        .contentShape(Rectangle())
                }
                .buttonStyle(StillroomQuietStyle())
                Text("Exported.")
                    .font(StillroomType.caption)
                    .foregroundStyle(StillroomPaint.muted)
            }
        }
        .padding(StillroomMeasure.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .stillroomCard()
    }

    private var dataCard: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
            Text("DATA")
                .font(StillroomType.micro)
                .foregroundStyle(StillroomPaint.muted)
                .tracking(1.4)
            Button("Replay walkthrough") {
                session.replayOnboarding()
            }
            .buttonStyle(StillroomQuietStyle())
            Button("Reset all data", role: .destructive) {
                confirmReset = true
            }
            .buttonStyle(StillroomDestroyStyle())
        }
        .padding(StillroomMeasure.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .stillroomCard()
    }

    private func exportFault(_ fault: String) -> some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(1)) {
            Text("Export failed.")
                .font(StillroomType.headline)
                .foregroundStyle(StillroomPaint.ink)
            Text(fault)
                .font(StillroomType.body)
                .foregroundStyle(StillroomPaint.muted)
            Button("Retry") {
                Task { await session.retryDesk() }
            }
            .buttonStyle(StillroomFillStyle())
        }
        .padding(StillroomMeasure.space(2))
        .stillroomCard()
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(StillroomType.micro)
                .foregroundStyle(StillroomPaint.muted)
                .tracking(1.3)
            Spacer()
            Text(value)
                .font(StillroomType.headline)
                .foregroundStyle(StillroomPaint.ink)
                .monospacedDigit()
        }
        .frame(minHeight: StillroomMeasure.hit)
    }

    private func pullRule(label: String, line: String) -> some View {
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
