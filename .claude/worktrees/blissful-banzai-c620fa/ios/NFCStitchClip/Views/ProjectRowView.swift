import SwiftUI

struct ProjectRowView: View {
    let project: Project

    private var workTimeSummary: String {
        let secs = project.estimatedWorkTime
        guard secs > 0 else { return "" }
        if secs < 3600 { return String(format: "~%.0f min", secs / 60) }
        return String(format: "~%.1f hrs", secs / 3600)
    }

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(project.name).font(.headline)
                    if project.isCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }
                Text("Started \(project.startDate.formatted(.dateTime.month(.abbreviated).day().year()))")
                    .font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text("\(project.allWriteEvents.count) writes")
                    if !workTimeSummary.isEmpty {
                        Text("·").foregroundStyle(.secondary)
                        Text(workTimeSummary)
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let path = project.imagePath,
           let image = ImageStorageService.shared.load(filename: path) {
            Image(uiImage: image)
                .resizable().scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 52, height: 52)
                .overlay(Image(systemName: "photo").foregroundStyle(.quaternary))
        }
    }
}
