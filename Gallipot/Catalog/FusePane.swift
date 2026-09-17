import SwiftUI

/// Identity plus inline best-before. Landing a Lot is the only write from this sheet.
struct FusePane: View {
    @Bindable var desk: CaptureDesk
    var field: FocusState<CaptureField?>.Binding
    @Environment(StillroomSession.self) private var session

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
                identityBlock
                if let fault = desk.fault {
                    Text(fault)
                        .font(StillroomType.body)
                        .foregroundStyle(StillroomPaint.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                DatePicker(
                    "Best before",
                    selection: $desk.bestBefore,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(StillroomPaint.accent)
                .padding(StillroomMeasure.space(1))
                .stillroomCard()

                Stepper(value: $desk.quantity, in: 1 ... 99) {
                    HStack {
                        Text("QTY")
                            .font(StillroomType.micro)
                            .foregroundStyle(StillroomPaint.muted)
                            .tracking(1.4)
                        Text(FaceInk.quantity(desk.quantity))
                            .font(StillroomType.headline)
                            .foregroundStyle(StillroomPaint.ink)
                            .monospacedDigit()
                    }
                    .frame(minHeight: StillroomMeasure.hit)
                }
                .padding(.horizontal, StillroomMeasure.space(2))
                .stillroomCard()

                Button("Land") {
                    field.wrappedValue = nil
                    Task { await desk.land(using: session) }
                }
                .buttonStyle(StillroomFillStyle())
                .disabled(desk.working)

                Button("Back") {
                    desk.backToHunt()
                }
                .buttonStyle(StillroomQuietStyle())
            }
            .padding(StillroomMeasure.space(2))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(StillroomPaint.background)
        .contentMargins(.bottom, StillroomMeasure.space(3), for: .scrollContent)
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private var identityBlock: some View {
        switch desk.phase {
        case .fuse(let tin):
            HStack(alignment: .center, spacing: StillroomMeasure.space(2)) {
                thumb(tin.imageURL)
                VStack(alignment: .leading, spacing: 0) {
                    Text("TIN")
                        .font(StillroomType.micro)
                        .foregroundStyle(StillroomPaint.muted)
                        .tracking(1.4)
                    Text(tin.name)
                        .font(StillroomType.title)
                        .foregroundStyle(StillroomPaint.ink)
                        .lineLimit(2)
                    Text(tin.brand ?? tin.barcode)
                        .font(StillroomType.caption)
                        .foregroundStyle(StillroomPaint.muted)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(StillroomMeasure.space(2))
            .stillroomCard()
        case .name(let code):
            VStack(alignment: .leading, spacing: StillroomMeasure.space(1)) {
                Text("CODE")
                    .font(StillroomType.micro)
                    .foregroundStyle(StillroomPaint.muted)
                    .tracking(1.4)
                Text(code)
                    .font(StillroomType.headline)
                    .foregroundStyle(StillroomPaint.ink)
                    .textSelection(.enabled)
                TextField("Tin name", text: $desk.draftName)
                    .font(StillroomType.body)
                    .focused(field, equals: .name)
                    .padding(.horizontal, StillroomMeasure.space(2))
                    .frame(minHeight: StillroomMeasure.hit)
                    .stillroomCard()
            }
        case .hunt:
            EmptyView()
        }
    }

    @ViewBuilder
    private func thumb(_ raw: String?) -> some View {
        if let raw, let url = URL(string: raw) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Image("glp_ProductPlaceholder")
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(width: StillroomMeasure.space(8), height: StillroomMeasure.space(8))
            .clipShape(RoundedRectangle(cornerRadius: StillroomMeasure.chipRadius, style: .continuous))
            .accessibilityHidden(true)
        } else {
            Image("glp_ProductPlaceholder")
                .resizable()
                .scaledToFit()
                .frame(width: StillroomMeasure.space(8), height: StillroomMeasure.space(8))
                .accessibilityHidden(true)
        }
    }
}
