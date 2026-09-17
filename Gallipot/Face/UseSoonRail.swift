import SwiftUI

/// UseSoon home. One hero Face, then thinner Face rows. Pull is the persisted verb.
struct UseSoonRail: View {
    @Environment(StillroomSession.self) private var session
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if let fault = session.railFault, session.faces.isEmpty {
                StillroomFaultCutout(
                    headline: "Use Soon did not update.",
                    line: fault,
                    retry: { session.retryRail() }
                )
            } else if session.faces.isEmpty {
                StillroomCutout(
                    artName: "glp_EmptyHome",
                    headline: "The pantry is empty.",
                    line: "Scan the first tin.",
                    verb: "Scan",
                    action: { session.presentScan() }
                )
            } else if sizeClass == .regular {
                padRail
            } else {
                phoneRail
            }
        }
        .background(StillroomPaint.background.ignoresSafeArea())
        .navigationTitle("Use Soon")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Undo") {
                    Task { await session.undoLast() }
                }
                .disabled(!session.canUndo || session.verbBusy)
                .frame(minHeight: StillroomMeasure.hit)
                .contentShape(Rectangle())
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    session.presentScan()
                } label: {
                    Image(systemName: "barcode.viewfinder")
                        .frame(minWidth: StillroomMeasure.hit, minHeight: StillroomMeasure.hit)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Scan a tin")
                Button {
                    session.presentSettings()
                } label: {
                    Image(systemName: "gearshape")
                        .frame(minWidth: StillroomMeasure.hit, minHeight: StillroomMeasure.hit)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Settings")
            }
        }
    }

    private var phoneRail: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
                jobBand
                if let fault = session.railFault {
                    faultBanner(fault)
                }
                if let hero = session.hero {
                    FaceHeroCard(face: hero, behindLots: behindLots(for: hero)) {
                        Task { await session.pullFace(hero.bay.id) }
                    }
                }
                ForEach(restFaces) { face in
                    FaceThinRow(
                        face: face,
                        behindLots: behindLots(for: face),
                        pull: { Task { await session.pullFace(face.bay.id) } },
                        openBay: { session.openBay(face.bay.id) }
                    )
                }
                pantryJump
                facingCue
            }
            .padding(.horizontal, StillroomMeasure.space(2))
            .padding(.top, StillroomMeasure.space(1))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentMargins(.bottom, StillroomMeasure.space(3), for: .scrollContent)
        .scrollDismissesKeyboard(.interactively)
    }

    private var padRail: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
            jobBand
            if let fault = session.railFault {
                faultBanner(fault)
            }
            HStack(alignment: .top, spacing: StillroomMeasure.space(2)) {
                if let hero = session.hero {
                    FaceHeroCard(face: hero, behindLots: behindLots(for: hero)) {
                        Task { await session.pullFace(hero.bay.id) }
                    }
                }
                behindBoard
            }
            ForEach(restFaces) { face in
                FaceThinRow(
                    face: face,
                    behindLots: behindLots(for: face),
                    pull: { Task { await session.pullFace(face.bay.id) } },
                    openBay: { session.openBay(face.bay.id) }
                )
            }
            pantryJump
            facingCue
        }
        .padding(.horizontal, StillroomMeasure.space(2))
        .padding(.top, StillroomMeasure.space(1))
        .padding(.bottom, StillroomMeasure.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .stillroomFillCanvas()
    }

    private var restFaces: [Face] {
        Array(session.faces.dropFirst())
    }

    private var jobBand: some View {
        ZStack(alignment: .bottomLeading) {
            Image("glp_HeaderDecor")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: StillroomMeasure.space(7))
                .clipped()
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text("Pull the facing tin.")
                    .font(StillroomType.title)
                    .foregroundStyle(StillroomPaint.ink)
                    .lineLimit(2)
                HStack(alignment: .firstTextBaseline, spacing: StillroomMeasure.space(1)) {
                    Text(FaceInk.integer(session.faces.count))
                        .font(StillroomType.micro)
                        .foregroundStyle(StillroomPaint.ink)
                        .monospacedDigit()
                    Text("TO PULL")
                        .font(StillroomType.micro)
                        .foregroundStyle(StillroomPaint.muted)
                        .tracking(1.2)
                    Spacer(minLength: 0)
                    Text(FaceInk.integer(session.spentCount))
                        .font(StillroomType.micro)
                        .foregroundStyle(StillroomPaint.ink)
                        .monospacedDigit()
                    Text("SPENT")
                        .font(StillroomType.micro)
                        .foregroundStyle(StillroomPaint.muted)
                        .tracking(1.2)
                }
                .padding(.top, StillroomMeasure.space(1))
            }
            .padding(StillroomMeasure.space(2))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .stillroomCard()
    }

    private var behindBoard: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
            Text("BEHIND THE FACE")
                .font(StillroomType.micro)
                .foregroundStyle(StillroomPaint.muted)
                .tracking(1.4)
            if let hero = session.hero {
                Text(hero.bay.name)
                    .font(StillroomType.headline)
                    .foregroundStyle(StillroomPaint.ink)
                    .lineLimit(1)
                behindLotsBlock(behindLots(for: hero))
            }
            Text("ON THE RAIL")
                .font(StillroomType.micro)
                .foregroundStyle(StillroomPaint.muted)
                .tracking(1.4)
                .padding(.top, StillroomMeasure.space(1))
            ForEach(session.faces) { face in
                Button {
                    session.openBay(face.bay.id)
                } label: {
                    railFaceReadout(face)
                }
                .buttonStyle(StillroomPressStyle())
                .accessibilityLabel("Open \(face.bay.name)")
            }
        }
        .padding(StillroomMeasure.space(2))
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .stillroomCard()
    }

    private var pantryJump: some View {
        Button {
            session.presentPantry()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("PANTRY")
                        .font(StillroomType.micro)
                        .foregroundStyle(StillroomPaint.muted)
                        .tracking(1.2)
                    Text("\(FaceInk.integer(session.bayCount)) tins stacked.")
                        .font(StillroomType.caption)
                        .foregroundStyle(StillroomPaint.ink)
                        .lineLimit(1)
                }
                Spacer()
                if session.spentCount > 0 {
                    Text("\(FaceInk.integer(session.spentCount)) spent")
                        .font(StillroomType.caption)
                        .foregroundStyle(StillroomPaint.ink)
                        .monospacedDigit()
                }
                Image(systemName: "chevron.right")
                    .foregroundStyle(StillroomPaint.muted)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, StillroomMeasure.space(2))
            .frame(maxWidth: .infinity, minHeight: StillroomMeasure.hit, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(StillroomPressStyle())
        .stillroomCard()
        .accessibilityLabel("Open Pantry")
    }

    private var facingCue: some View {
        Button {
            session.presentFacing()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("OLDER FIRST")
                        .font(StillroomType.micro)
                        .foregroundStyle(StillroomPaint.muted)
                        .tracking(1.2)
                    Text("A newer pack stays behind.")
                        .font(StillroomType.caption)
                        .foregroundStyle(StillroomPaint.ink)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(StillroomPaint.muted)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, StillroomMeasure.space(2))
            .frame(maxWidth: .infinity, minHeight: StillroomMeasure.hit, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(StillroomPressStyle())
        .stillroomCard()
        .accessibilityLabel("How Pull works")
    }

    private func behindLots(for face: Face) -> [Lot] {
        guard let stack = session.stacks.first(where: { $0.bay.id == face.bay.id }) else { return [] }
        return Array(stack.liveLots.dropFirst())
    }

    @ViewBuilder
    private func behindLotsBlock(_ stacked: [Lot]) -> some View {
        if stacked.isEmpty {
            Text("No later pack on this Face. Pull takes the date in front.")
                .font(StillroomType.body)
                .foregroundStyle(StillroomPaint.ink)
        } else {
            ForEach(stacked) { lot in
                behindRow(lot)
            }
        }
    }

    private func railFaceReadout(_ face: Face) -> some View {
        let stacked = behindLots(for: face)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: StillroomMeasure.space(1)) {
                Text(face.bay.name)
                    .font(StillroomType.caption)
                    .foregroundStyle(StillroomPaint.ink)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(FaceInk.daysLeft(face.daysLeft))
                    .font(StillroomType.headline)
                    .foregroundStyle(StillroomPaint.ink)
                    .monospacedDigit()
                Text("DAYS")
                    .font(StillroomType.micro)
                    .foregroundStyle(StillroomPaint.muted)
                    .tracking(1.2)
            }
            if stacked.isEmpty {
                Text("No later pack")
                    .font(StillroomType.caption)
                    .foregroundStyle(StillroomPaint.muted)
            } else {
                ForEach(stacked) { lot in
                    HStack(spacing: StillroomMeasure.space(1)) {
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
                            .foregroundStyle(StillroomPaint.muted)
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding(.vertical, StillroomMeasure.space(1))
        .frame(maxWidth: .infinity, minHeight: StillroomMeasure.hit, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func behindRow(_ lot: Lot) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: StillroomMeasure.space(1)) {
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
        .frame(minHeight: StillroomMeasure.hit)
    }

    private func faultBanner(_ text: String) -> some View {
        HStack(alignment: .center, spacing: StillroomMeasure.space(1)) {
            Text(text)
                .font(StillroomType.body)
                .foregroundStyle(StillroomPaint.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Retry") {
                session.retryRail()
            }
            .buttonStyle(StillroomChipFillStyle())
        }
        .padding(StillroomMeasure.space(2))
        .stillroomCard()
    }
}
