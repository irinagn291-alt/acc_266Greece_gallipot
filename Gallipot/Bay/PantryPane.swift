import SwiftUI

/// Pantry lists Bays with stacked Lots behind each Face, plus Spent until Cull.
struct PantryPane: View {
    @Environment(StillroomSession.self) private var session
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if let fault = session.pantryFault, session.stacks.isEmpty {
                StillroomFaultCutout(
                    headline: "Pantry did not update.",
                    line: fault,
                    retry: { session.retryPantry() }
                )
            } else if session.stacks.isEmpty {
                StillroomCutout(
                    artName: "glp_EmptyList",
                    headline: "No tins yet.",
                    line: "Scan a tin on Use Soon.",
                    verb: "Scan",
                    action: { session.presentScan() }
                )
            } else if sizeClass == .regular {
                padBoard
            } else {
                phoneList
            }
        }
        .background(StillroomPaint.background.ignoresSafeArea())
        .navigationTitle("Pantry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    session.presentScan()
                } label: {
                    Image(systemName: "barcode.viewfinder")
                        .frame(minWidth: StillroomMeasure.hit, minHeight: StillroomMeasure.hit)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Scan a tin")
            }
        }
    }

    private var phoneList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
                pantryJob
                if let fault = session.pantryFault {
                    pantryFault(fault)
                }
                if session.spentCount > 0 && !session.stacks.contains(where: { $0.face == nil && !$0.spentLots.isEmpty }) {
                    SpentCullBar(count: session.spentCount) {
                        Task { await session.cullSpent() }
                    }
                }
                ForEach(session.stacks) { stack in
                    pantryBay(stack, showCull: stack.face == nil && !stack.spentLots.isEmpty)
                }
            }
            .padding(.horizontal, StillroomMeasure.space(2))
            .padding(.top, StillroomMeasure.space(1))
            .padding(.bottom, StillroomMeasure.space(3))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var padBoard: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
            pantryJob
            if let fault = session.pantryFault {
                pantryFault(fault)
            }
            if session.spentCount > 0 {
                SpentCullBar(count: session.spentCount) {
                    Task { await session.cullSpent() }
                }
            }
            Grid(alignment: .topLeading, horizontalSpacing: StillroomMeasure.space(2), verticalSpacing: StillroomMeasure.space(2)) {
                ForEach(Array(padPairs.enumerated()), id: \.offset) { _, pair in
                    if let second = pair.1 {
                        GridRow(alignment: .top) {
                            pantryBay(pair.0, showCull: false)
                            pantryBay(second, showCull: false)
                        }
                    } else {
                        GridRow(alignment: .top) {
                            pantryBay(pair.0, showCull: false)
                                .gridCellColumns(2)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, StillroomMeasure.space(2))
        .padding(.top, StillroomMeasure.space(1))
        .padding(.bottom, StillroomMeasure.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .stillroomFillCanvas()
    }

    private var padPairs: [(BayStack, BayStack?)] {
        let stacks = session.stacks
        var pairs: [(BayStack, BayStack?)] = []
        var index = 0
        while index < stacks.count {
            let first = stacks[index]
            let second = index + 1 < stacks.count ? stacks[index + 1] : nil
            pairs.append((first, second))
            index += 2
        }
        return pairs
    }

    private func pantryBay(_ stack: BayStack, showCull: Bool) -> some View {
        PantryBayCard(
            stack: stack,
            showCull: showCull,
            open: { session.openBay(stack.bay.id) },
            cull: { Task { await session.cullSpent() } }
        )
    }

    private var pantryJob: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(1)) {
            Text("Open a tin to see stacked dates.")
                .font(StillroomType.headline)
                .foregroundStyle(StillroomPaint.ink)
            Text("Cull spent dates from this list.")
                .font(StillroomType.caption)
                .foregroundStyle(StillroomPaint.muted)
        }
        .padding(StillroomMeasure.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .stillroomCard()
    }

    private func pantryFault(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(StillroomType.body)
                .foregroundStyle(StillroomPaint.ink)
            Spacer(minLength: 0)
            Button("Retry") { session.retryPantry() }
                .buttonStyle(StillroomChipFillStyle())
        }
        .padding(StillroomMeasure.space(2))
        .stillroomCard()
    }
}

/// Pantry card. Open is the Face. Cull sits on Spent so that verb has a tap on this list.
struct PantryBayCard: View {
    var stack: BayStack
    var showCull: Bool
    var open: () -> Void
    var cull: () -> Void
    @State private var confirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: open) {
                BayStackRow(stack: stack, expanded: true)
            }
            .buttonStyle(StillroomPressStyle())

            if showCull {
                Button("Cull") {
                    confirm = true
                }
                .buttonStyle(StillroomDestroyStyle())
                .padding(.horizontal, StillroomMeasure.space(2))
                .padding(.bottom, StillroomMeasure.space(2))
                .accessibilityLabel("Cull spent dates")
            }
        }
        .stillroomCard()
        .confirmationDialog(
            "Cull spent dates. They leave this device.",
            isPresented: $confirm,
            titleVisibility: .visible
        ) {
            Button("Cull", role: .destructive, action: cull)
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct BayStackRow: View {
    var stack: BayStack
    var expanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(1)) {
            HStack(spacing: StillroomMeasure.space(2)) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(stack.bay.name)
                        .font(StillroomType.headline)
                        .foregroundStyle(StillroomPaint.ink)
                        .lineLimit(1)
                    Text(stack.bay.brand ?? stack.bay.barcode)
                        .font(StillroomType.caption)
                        .foregroundStyle(StillroomPaint.muted)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 0) {
                    if let face = stack.face {
                        Text(FaceInk.daysLeft(face.daysLeft))
                            .font(StillroomType.title)
                            .foregroundStyle(StillroomPaint.ink)
                            .monospacedDigit()
                        Text("DAYS")
                            .font(StillroomType.micro)
                            .foregroundStyle(StillroomPaint.muted)
                            .tracking(1.2)
                    } else {
                        Text("SPENT")
                            .font(StillroomType.micro)
                            .foregroundStyle(StillroomPaint.muted)
                            .tracking(1.2)
                        Text(FaceInk.integer(stack.spentLots.count))
                            .font(StillroomType.title)
                            .foregroundStyle(StillroomPaint.ink)
                            .monospacedDigit()
                    }
                }
                Image(systemName: "chevron.right")
                    .foregroundStyle(StillroomPaint.muted)
                    .accessibilityHidden(true)
            }

            if expanded {
                VStack(spacing: 0) {
                    ForEach(Array(stack.liveLots.enumerated()), id: \.element.id) { index, lot in
                        if index > 0 {
                            dateRule
                        }
                        dateRow(
                            role: lot.id == stack.face?.lot.id ? "FACE" : "BEHIND",
                            lot: lot,
                            ink: lot.id == stack.face?.lot.id,
                            days: lot.id == stack.face?.lot.id ? stack.face?.daysLeft : nil
                        )
                    }
                    ForEach(Array(stack.spentLots.enumerated()), id: \.element.id) { index, lot in
                        if index > 0 || !stack.liveLots.isEmpty {
                            dateRule
                        }
                        dateRow(role: "SPENT", lot: lot, ink: false, days: nil)
                    }
                }
            } else if !dateLine.isEmpty {
                Text(dateLine)
                    .font(StillroomType.caption)
                    .foregroundStyle(StillroomPaint.ink)
                    .lineLimit(2)
            }
        }
        .padding(StillroomMeasure.space(2))
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }

    private var dateRule: some View {
        Rectangle()
            .fill(StillroomPaint.muted.opacity(0.45))
            .frame(height: StillroomMeasure.hairline)
    }

    private func dateRow(role: String, lot: Lot, ink: Bool, days: Int?) -> some View {
        HStack(alignment: .center, spacing: StillroomMeasure.space(2)) {
            VStack(alignment: .leading, spacing: 0) {
                Text(role)
                    .font(StillroomType.micro)
                    .foregroundStyle(StillroomPaint.muted)
                    .tracking(1.2)
                Text(FaceInk.bestBefore(lot.bestBeforeDaykey))
                    .font(StillroomType.headline)
                    .foregroundStyle(ink ? StillroomPaint.ink : StillroomPaint.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 0) {
                if let days {
                    Text(FaceInk.daysLeft(days))
                        .font(StillroomType.headline)
                        .foregroundStyle(StillroomPaint.ink)
                        .monospacedDigit()
                    Text("DAYS")
                        .font(StillroomType.micro)
                        .foregroundStyle(StillroomPaint.muted)
                        .tracking(1.2)
                }
                HStack(spacing: StillroomMeasure.space(1)) {
                    Text("QTY")
                        .font(StillroomType.micro)
                        .foregroundStyle(StillroomPaint.muted)
                        .tracking(1.2)
                    Text(FaceInk.quantity(lot.quantity))
                        .font(StillroomType.headline)
                        .foregroundStyle(StillroomPaint.ink)
                        .monospacedDigit()
                }
            }
        }
        .frame(minHeight: StillroomMeasure.hit)
    }

    private var dateLine: String {
        let live = stack.liveLots.map { FaceInk.bestBefore($0.bestBeforeDaykey) }
        if live.isEmpty { return "" }
        return live.joined(separator: ", ")
    }

    private var label: String {
        let lots = FaceInk.integer(stack.liveLots.count)
        if let face = stack.face {
            return "\(stack.bay.name), \(FaceInk.daysLeft(face.daysLeft)) days left, \(lots) dates"
        }
        return "\(stack.bay.name), spent"
    }
}
