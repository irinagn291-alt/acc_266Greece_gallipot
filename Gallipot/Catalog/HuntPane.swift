import SwiftUI

/// Camera, sample chips, search, manual code, and best-before. Continues to the system alert. Never Allow or Enable.
struct HuntPane: View {
    @Bindable var desk: CaptureDesk
    var field: FocusState<CaptureField?>.Binding
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(StillroomSession.self) private var session
    @ScaledMetric(relativeTo: .body) private var displaySize = StillroomMeasure.displayPoints

    var body: some View {
        VStack(spacing: 0) {
            if seeking {
                if showsHuntJob {
                    huntJob
                        .padding(.horizontal, StillroomMeasure.space(2))
                        .padding(.top, StillroomMeasure.space(2))
                        .padding(.bottom, StillroomMeasure.space(1))
                }
                seekBar
                    .padding(.horizontal, StillroomMeasure.space(2))
                    .padding(.top, StillroomMeasure.space(1))
                hitsList
            } else if sizeClass == .regular {
                padIdle
            } else {
                phoneIdle
            }
            if desk.showSpinner {
                ProgressView()
                    .tint(StillroomPaint.accent)
                    .frame(height: StillroomMeasure.hit)
            }
            if let fault = desk.fault {
                Text(fault)
                    .font(StillroomType.caption)
                    .foregroundStyle(StillroomPaint.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, StillroomMeasure.space(2))
                    .padding(.top, StillroomMeasure.space(1))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(StillroomPaint.background)
        .scrollDismissesKeyboard(.interactively)
    }

    private var seeking: Bool {
        !desk.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var showsHuntJob: Bool {
        switch desk.access {
        case .noDevice, .authorized:
            return true
        default:
            return false
        }
    }

    private var phoneIdle: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
                if showsHuntJob {
                    huntJob
                }
                huntSurface
                seekBar
                bestBeforeBlock
                quantityBlock
                huntHint
            }
            .padding(.horizontal, StillroomMeasure.space(2))
            .padding(.top, StillroomMeasure.space(1))
            .padding(.bottom, StillroomMeasure.space(3))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var padIdle: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
            if showsHuntJob {
                huntJob
            }
            HStack(alignment: .top, spacing: StillroomMeasure.space(2)) {
                VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
                    huntSurface
                    seekBar
                    huntHint
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                bestBeforeBlock
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            landDesk
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(StillroomMeasure.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .stillroomFillCanvas()
    }

    private var landDesk: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
            identifiedWell
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            quantityBlock
            if let fault = desk.fault {
                Text(fault)
                    .font(StillroomType.body)
                    .foregroundStyle(StillroomPaint.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button("Land") {
                field.wrappedValue = nil
                Task { await desk.land(using: session) }
            }
            .buttonStyle(StillroomFillStyle())
            .disabled(desk.working)
            .accessibilityLabel("Land this tin")
            if showsLandBack {
                Button("Back") {
                    desk.backToHunt()
                }
                .buttonStyle(StillroomQuietStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var identifiedWell: some View {
        HStack(alignment: .top, spacing: StillroomMeasure.space(3)) {
            identifiedTin
                .frame(maxWidth: .infinity, alignment: .topLeading)
            pendingDate
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(StillroomMeasure.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .stillroomCard()
    }

    @ViewBuilder
    private var identifiedTin: some View {
        switch desk.phase {
        case .fuse(let tin):
            HStack(alignment: .center, spacing: StillroomMeasure.space(2)) {
                wellThumb(tin.imageURL)
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
            }
        case .name(let code):
            VStack(alignment: .leading, spacing: StillroomMeasure.space(1)) {
                Text("TIN")
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
            VStack(alignment: .leading, spacing: StillroomMeasure.space(1)) {
                Text("TIN")
                    .font(StillroomType.micro)
                    .foregroundStyle(StillroomPaint.muted)
                    .tracking(1.4)
                Text("Pick a sample.")
                    .font(StillroomType.title)
                    .foregroundStyle(StillroomPaint.ink)
                Text("Land writes that date behind the Face.")
                    .font(StillroomType.body)
                    .foregroundStyle(StillroomPaint.ink)
            }
        }
    }

    private var pendingDate: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("THIS DATE")
                .font(StillroomType.micro)
                .foregroundStyle(StillroomPaint.muted)
                .tracking(1.4)
            Text(FaceInk.daysLeft(pendingDays))
                .font(StillroomType.display(displaySize))
                .foregroundStyle(StillroomPaint.accent)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, StillroomMeasure.space(1))
            Text("DAYS LEFT")
                .font(StillroomType.micro)
                .foregroundStyle(StillroomPaint.muted)
                .tracking(1.4)
            Text(FaceInk.bestBefore(pendingDaykey))
                .font(StillroomType.headline)
                .foregroundStyle(StillroomPaint.ink)
                .padding(.top, StillroomMeasure.space(1))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(FaceInk.daysLeft(pendingDays)) days until \(FaceInk.bestBefore(pendingDaykey))")
    }

    private var pendingDaykey: Int {
        Daykey.make(desk.bestBefore, calendar: .current)
    }

    private var pendingDays: Int {
        Daykey.daysLeft(bestBefore: pendingDaykey, today: Date(), calendar: .current)
    }

    private var showsLandBack: Bool {
        switch desk.phase {
        case .hunt:
            return false
        case .fuse, .name:
            return true
        }
    }

    private var huntJob: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Scan a tin.")
                .font(StillroomType.title)
                .foregroundStyle(StillroomPaint.ink)
            Text("Then set the best-before.")
                .font(StillroomType.body)
                .foregroundStyle(StillroomPaint.muted)
                .padding(.top, StillroomMeasure.space(1))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var huntHint: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(1)) {
            Text("Pick a sample, type a code, or search a name.")
                .font(StillroomType.body)
                .foregroundStyle(StillroomPaint.ink)
            Text("Land writes a Lot behind that Face.")
                .font(StillroomType.caption)
                .foregroundStyle(StillroomPaint.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var huntSurface: some View {
        switch desk.access {
        case .checking:
            StillroomPaint.background
                .frame(maxWidth: .infinity, minHeight: StillroomMeasure.space(8))
        case .needContinue:
            permissionContinue
        case .blocked:
            permissionBlocked
        case .authorized:
            cameraStage
        case .noDevice:
            sampleStage
        }
    }

    private var permissionContinue: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
            Text("Read the tin")
                .font(StillroomType.title)
                .foregroundStyle(StillroomPaint.ink)
            Text("The camera names a grocery tin so a date can land on Use Soon.")
                .font(StillroomType.body)
                .foregroundStyle(StillroomPaint.muted)
            sampleStage
            Button("Continue") {
                desk.continueToSystemAlert()
            }
            .buttonStyle(StillroomFillStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var permissionBlocked: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
            Text("Camera is off.")
                .font(StillroomType.title)
                .foregroundStyle(StillroomPaint.ink)
            Text("Open Settings, or type a code.")
                .font(StillroomType.body)
                .foregroundStyle(StillroomPaint.muted)
            Button("Open Settings") {
                desk.openAppSettings()
            }
            .buttonStyle(StillroomQuietStyle())
            sampleStage
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cameraStage: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(2)) {
            cameraPreview
            sampleStage
        }
    }

    private var cameraPreview: some View {
        ZStack {
            TinHuntPreview(isActive: desk.cameraLive) { payload in
                Task { await desk.handlePayload(payload) }
            }
            TinHuntReticle()
                .stroke(StillroomPaint.accent, lineWidth: StillroomMeasure.hairline)
                .padding(StillroomMeasure.space(6))
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: StillroomMeasure.space(24))
        .clipShape(RoundedRectangle(cornerRadius: StillroomMeasure.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: StillroomMeasure.radius, style: .continuous)
                .stroke(StillroomPaint.muted.opacity(0.45), lineWidth: StillroomMeasure.hairline)
        )
    }

    private var sampleStage: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(1)) {
            Text("SAMPLE CODES")
                .font(StillroomType.micro)
                .foregroundStyle(StillroomPaint.muted)
                .tracking(1.4)
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: StillroomMeasure.space(20)), spacing: StillroomMeasure.space(1)),
                ],
                alignment: .leading,
                spacing: StillroomMeasure.space(1)
            ) {
                ForEach(desk.sampleTins) { tin in
                    Button {
                        desk.pick(tin)
                    } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(tin.name)
                                .font(StillroomType.caption)
                                .foregroundStyle(StillroomPaint.ink)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(tin.barcode)
                                .font(StillroomType.micro)
                                .foregroundStyle(StillroomPaint.muted)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(.horizontal, StillroomMeasure.space(2))
                        .padding(.vertical, StillroomMeasure.space(1))
                        .frame(maxWidth: .infinity, minHeight: StillroomMeasure.hit, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(StillroomPressStyle())
                    .stillroomChip()
                    .disabled(desk.working)
                    .accessibilityLabel("Pick \(tin.name)")
                }
            }
            manualField
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bestBeforeBlock: some View {
        VStack(alignment: .leading, spacing: StillroomMeasure.space(1)) {
            Text("BEST BEFORE")
                .font(StillroomType.micro)
                .foregroundStyle(StillroomPaint.muted)
                .tracking(1.4)
            DatePicker(
                "Best before",
                selection: $desk.bestBefore,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(StillroomPaint.accent)
            .labelsHidden()
            .padding(StillroomMeasure.space(1))
            .stillroomCard()
            .accessibilityLabel("Best before")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quantityBlock: some View {
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
    }

    private var seekBar: some View {
        HStack(spacing: StillroomMeasure.space(1)) {
            TextField("Search a tin name", text: $desk.query)
                .font(StillroomType.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused(field, equals: .search)
                .onSubmit { desk.submitQuery() }
                .onChange(of: desk.query) { _, _ in
                    desk.submitQuery()
                }
            if !desk.query.isEmpty {
                Button {
                    desk.query = ""
                    desk.submitQuery()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .frame(minWidth: StillroomMeasure.hit, minHeight: StillroomMeasure.hit)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, StillroomMeasure.space(2))
        .frame(minHeight: StillroomMeasure.hit)
        .stillroomCard()
    }

    private var hitsList: some View {
        List {
            if desk.hits.isEmpty {
                VStack(alignment: .leading, spacing: StillroomMeasure.space(1)) {
                    Text("No tins matched.")
                        .font(StillroomType.headline)
                        .foregroundStyle(StillroomPaint.ink)
                    Text("Type a code or pick a sample.")
                        .font(StillroomType.body)
                        .foregroundStyle(StillroomPaint.muted)
                    Button("Clear search") {
                        desk.query = ""
                        desk.submitQuery()
                    }
                    .buttonStyle(StillroomFillStyle())
                }
                .padding(.vertical, StillroomMeasure.space(1))
                .listRowBackground(StillroomPaint.surface)
                .listRowSeparator(.hidden)
            } else {
                ForEach(desk.hits) { tin in
                    Button {
                        desk.pick(tin)
                    } label: {
                        HStack(spacing: StillroomMeasure.space(2)) {
                            tinThumb(tin)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(tin.name)
                                    .font(StillroomType.headline)
                                    .foregroundStyle(StillroomPaint.ink)
                                    .lineLimit(1)
                                Text(tin.brand ?? tin.barcode)
                                    .font(StillroomType.caption)
                                    .foregroundStyle(StillroomPaint.muted)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: StillroomMeasure.hit, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(StillroomPressStyle())
                    .listRowBackground(StillroomPaint.surface)
                    .onAppear {
                        if tin.barcode == desk.hits.last?.barcode {
                            desk.loadMore()
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .contentMargins(.bottom, StillroomMeasure.space(3), for: .scrollContent)
    }

    private var manualField: some View {
        HStack(spacing: StillroomMeasure.space(1)) {
            TextField("Code or URL", text: $desk.manual)
                .font(StillroomType.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .focused(field, equals: .manual)
                .onSubmit {
                    Task { await desk.submitManual() }
                }
            Button("Look up") {
                Task { await desk.submitManual() }
            }
            .buttonStyle(StillroomChipFillStyle())
            .disabled(desk.working)
        }
        .padding(.horizontal, StillroomMeasure.space(1))
        .stillroomCard()
    }

    @ViewBuilder
    private func wellThumb(_ raw: String?) -> some View {
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
            .frame(width: StillroomMeasure.space(10), height: StillroomMeasure.space(10))
            .clipShape(RoundedRectangle(cornerRadius: StillroomMeasure.chipRadius, style: .continuous))
            .accessibilityHidden(true)
        } else {
            Image("glp_ProductPlaceholder")
                .resizable()
                .scaledToFit()
                .frame(width: StillroomMeasure.space(10), height: StillroomMeasure.space(10))
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func tinThumb(_ tin: TinIdentity) -> some View {
        if let raw = tin.imageURL, let url = URL(string: raw) {
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
            .frame(width: StillroomMeasure.hit, height: StillroomMeasure.hit)
            .clipShape(RoundedRectangle(cornerRadius: StillroomMeasure.chipRadius, style: .continuous))
            .accessibilityHidden(true)
        } else {
            Image("glp_ProductPlaceholder")
                .resizable()
                .scaledToFit()
                .frame(width: StillroomMeasure.hit, height: StillroomMeasure.hit)
                .accessibilityHidden(true)
        }
    }
}
