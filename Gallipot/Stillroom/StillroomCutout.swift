import SwiftUI

/// Full-page empty or error cutout. One headline, one line, bottom full-width verb.
struct StillroomCutout: View {
    var artName: String
    var headline: String
    var line: String
    var verb: String
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: StillroomMeasure.space(2))
            Image(artName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: StillroomMeasure.space(35))
                .accessibilityHidden(true)
            Text(headline)
                .font(StillroomType.title)
                .foregroundStyle(StillroomPaint.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, StillroomMeasure.space(3))
            Text(line)
                .font(StillroomType.body)
                .foregroundStyle(StillroomPaint.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, StillroomMeasure.space(1))
            Spacer(minLength: StillroomMeasure.space(2))
            Button(verb, action: action)
                .buttonStyle(StillroomFillStyle())
        }
        .padding(.horizontal, StillroomMeasure.space(2))
        .padding(.bottom, StillroomMeasure.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(StillroomPaint.background)
    }
}

struct StillroomFaultCutout: View {
    var headline: String
    var line: String
    var retry: () -> Void

    var body: some View {
        StillroomCutout(
            artName: "glp_EmptyList",
            headline: headline,
            line: line,
            verb: "Retry",
            action: retry
        )
    }
}
