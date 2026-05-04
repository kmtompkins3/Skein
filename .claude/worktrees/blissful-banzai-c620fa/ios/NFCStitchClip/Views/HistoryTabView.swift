import SwiftUI

struct HistoryTabView: View {
    let project: Project

    private struct EventRow: Identifiable {
        let id: UUID
        let event: WriteEvent
        let tagLabel: String
        let elapsedText: String?
    }

    private var rows: [EventRow] {
        let sorted = project.tags
            .sorted { $0.firstWriteAt < $1.firstWriteAt }
        let tagLabels: [UUID: String] = Dictionary(
            uniqueKeysWithValues: sorted.enumerated().map { ($1.id, "Tag \($0 + 1)") }
        )
        let allEvents = project.allWriteEvents
            .sorted { $0.timestamp < $1.timestamp }

        return allEvents.enumerated().map { idx, event in
            let elapsed: String? = idx > 0
                ? formatGap(event.timestamp.timeIntervalSince(allEvents[idx - 1].timestamp))
                : nil
            let tagID = project.tags.first { $0.writeEvents.contains { $0.id == event.id } }?.id
            return EventRow(
                id: event.id,
                event: event,
                tagLabel: tagID.flatMap { tagLabels[$0] } ?? "Tag",
                elapsedText: elapsed
            )
        }
        .reversed()
    }

    private func formatGap(_ gap: TimeInterval) -> String {
        if gap < 3600 { return "+\(Int(gap / 60)) min" }
        return String(format: "+%.1f hrs", gap / 3600)
    }

    private var workTimeText: String {
        let secs = project.estimatedWorkTime
        guard secs > 0 else { return "No time data yet" }
        if secs < 3600 { return String(format: "%.0f min", secs / 60) }
        return String(format: "%.2f hrs", secs / 3600)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Started \(project.startDate.formatted(.dateTime.month(.abbreviated).day().year()))")
                        .font(.subheadline)
                    Text("\(project.allWriteEvents.count) write events")
                        .font(.subheadline)
                    Text("Est. work time: \(workTimeText)")
                        .font(.subheadline).bold()
                    Text("Estimated based on time between tag writes")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            if rows.isEmpty {
                ContentUnavailableView(
                    "No History Yet",
                    systemImage: "clock",
                    description: Text("Write to a tag to begin tracking.")
                )
            } else {
                Section("Events") {
                    ForEach(rows) { row in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(row.event.timestamp.formatted(
                                    .dateTime.month(.abbreviated).day().hour().minute()
                                ))
                                .font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Text(row.tagLabel)
                                    .font(.caption2)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                            Text(row.event.noteContent.isEmpty ? "(no notes)" : row.event.noteContent)
                                .font(.subheadline)
                            if let elapsed = row.elapsedText {
                                Text("\(elapsed) since last write")
                                    .font(.caption).foregroundStyle(.tertiary)
                            } else {
                                Text("(first write)")
                                    .font(.caption).foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}
