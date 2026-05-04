import SwiftUI

struct ProjectRowView: View {
    let project: Project

    private static let tagColors: [Color] = [
        .skeinTangerine, .skeinMint, .skeinChampagne, .skeinPink,
        Color(red: 0.49, green: 0.68, blue: 0.79), Color(red: 0.72, green: 0.66, blue: 0.60),
    ]

    private var thumbnailColor: Color {
        let colors = Self.tagColors
        return colors[abs(project.id.hashValue) % colors.count]
    }

    private var tapCount: Int { project.allWriteEvents.count }

    private var workTimeSummary: String {
        let secs = project.estimatedWorkTime
        guard secs > 0 else { return "" }
        if secs < 3600 { return "~\(Int(secs / 60)) min" }
        return String(format: "~%.0f hrs", secs / 3600)
    }

    var body: some View {
        HStack(spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(project.name)
                        .font(Font.custom("Helvetica Neue", size: 15).weight(.semibold))
                        .foregroundStyle(Color.skeinCharcoal)
                        .tracking(-0.22)
                    if project.isCompleted {
                        Circle()
                            .fill(Color.skeinTangerine)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(Color.skeinCream)
                            )
                    }
                }
                Text("Started \(project.startDate.formatted(.dateTime.month(.abbreviated).day().year()))")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.skeinMuted)
                    .padding(.bottom, 4)

                HStack(spacing: 0) {
                    Text("\(tapCount) TAPS")
                    if !workTimeSummary.isEmpty {
                        Text("  ·  ")
                            .foregroundStyle(Color.skeinMuted.opacity(0.4))
                        Text(workTimeSummary.uppercased())
                    }
                }
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.skeinInk)
                .kerning(0.6)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.skeinMuted)
        }
        .padding(14)
        .background(Color.skeinCream)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.skeinHairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let path = project.imagePath,
           let image = ImageStorageService.shared.load(filename: path) {
            Image(uiImage: image)
                .resizable().scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            YarnThumbnail(size: 56, color: thumbnailColor, label: project.isCompleted ? "DONE" : "WIP")
        }
    }
}
