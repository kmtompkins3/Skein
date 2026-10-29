import SwiftUI

struct HistoryTabView: View {
    let project: Project

    private static let tagColors: [Color] = [
        .skeinTangerine, .skeinMint, .skeinChampagne, .skeinPink,
        Color(red: 0.49, green: 0.68, blue: 0.79), Color(red: 0.72, green: 0.66, blue: 0.60),
    ]

    private struct EventRow: Identifiable {
        let id:          UUID
        let event:       WriteEvent
        let tagLabel:    String
        let tagIndex:    Int
        let elapsedText: String?
    }

    private var rows: [EventRow] {
        let sorted = project.tags.sorted { $0.firstWriteAt < $1.firstWriteAt }
        let tagMeta: [UUID: (String, Int)] = Dictionary(
            uniqueKeysWithValues: sorted.enumerated().map { ($1.id, ("Tag \($0 + 1)", $0)) }
        )
        let allEvents = project.allWriteEvents.sorted { $0.timestamp < $1.timestamp }
        return allEvents.enumerated().map { idx, event in
            let elapsed: String? = idx > 0
                ? formatGap(event.timestamp.timeIntervalSince(allEvents[idx - 1].timestamp))
                : nil
            let tagID = project.tags.first { $0.writeEvents.contains { $0.id == event.id } }?.id
            let meta = tagID.flatMap { tagMeta[$0] }
            return EventRow(
                id: event.id, event: event,
                tagLabel: meta?.0 ?? "Tag",
                tagIndex: meta?.1 ?? 0,
                elapsedText: elapsed
            )
        }.reversed()
    }

    private func formatGap(_ gap: TimeInterval) -> String {
        guard gap > 0 && gap <= 43200 else { return "" }
        if gap < 3600 { return "+\(Int(gap / 60))m" }
        return String(format: "+%.1fh", gap / 3600)
    }

    private var workTimeText: String {
        let secs = project.estimatedWorkTime
        guard secs > 0 else { return "No time data yet" }
        let h = Int(secs / 3600)
        let m = Int((secs.truncatingRemainder(dividingBy: 3600)) / 60)
        if h == 0 { return "\(m)m" }
        return "\(h)h \(m)m"
    }

    private var activityBars: [CGFloat] {
        guard !project.allWriteEvents.isEmpty else { return [] }
        let events = project.allWriteEvents.sorted { $0.timestamp < $1.timestamp }
        guard let first = events.first?.timestamp else { return [] }
        let days = max(7, Int(Date.now.timeIntervalSince(first) / 86400) + 1)
        var counts = Array(repeating: 0, count: min(days, 30))
        for event in events {
            let dayIdx = Int(event.timestamp.timeIntervalSince(first) / 86400)
            let slot = min(dayIdx, counts.count - 1)
            counts[slot] += 1
        }
        let maxVal = CGFloat(counts.max() ?? 1)
        return counts.map { CGFloat($0) / maxVal }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                statPanel
                    .padding(.horizontal, 22)
                    .padding(.bottom, 18)

                sectionHeader
                timeline
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
            .padding(.top, 12)
        }
        .scrollIndicators(.hidden)
        .background(Color.skeinCream)
    }

    // MARK: Subviews

    private var statPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Time display
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                let parts = workTimeText.components(separatedBy: " ")
                if project.estimatedWorkTime > 0 {
                    Text(parts[0])
                        .font(Font.custom("Helvetica Neue", size: 44).weight(.bold))
                        .foregroundStyle(Color.skeinCream)
                        .tracking(-1.76)
                    if parts.count > 1 {
                        Text(parts[1])
                            .font(Font.custom("Helvetica Neue", size: 28).weight(.bold))
                            .foregroundStyle(Color.skeinCream)
                            .tracking(-0.84)
                    }
                } else {
                    Text("No time data yet")
                        .font(Font.custom("Helvetica Neue", size: 22).weight(.semibold))
                        .foregroundStyle(Color.skeinCream)
                }
                Spacer()
                Text("EST. WORK")
                    .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.skeinCream.opacity(0.55))
                    .kerning(1.8)
            }

            // Bar chart
            let bars = activityBars
            if !bars.isEmpty {
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(bars.indices, id: \.self) { i in
                        let isLast = i == bars.index(before: bars.endIndex)
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(
                                bars[i] == 0
                                    ? Color.white.opacity(0.18)
                                    : (isLast ? Color.skeinTangerine : Color.white.opacity(0.45 + 0.55 * bars[i]))
                            )
                            .frame(height: bars[i] == 0 ? 2 : max(4, 46 * bars[i]))
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 46)
                .padding(.top, 18)

                HStack {
                    Text(project.startDate.formatted(.dateTime.month(.abbreviated).day()))
                        .uppercased()
                    Spacer()
                    Text("·")
                    Spacer()
                    Text("TODAY")
                }
                .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.skeinCream.opacity(0.55))
                .kerning(1.4)
                .padding(.top, 10)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(Color.skeinCharcoal)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var sectionHeader: some View {
        Text("RECENT EVENTS · \(project.allWriteEvents.count) TOTAL")
            .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
            .foregroundStyle(Color.skeinMuted)
            .kerning(1.8)
            .padding(.horizontal, 24)
            .padding(.bottom, 10)
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            if rows.isEmpty {
                Text("No write events yet.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.skeinMuted)
                    .padding(.vertical, 24)
            } else {
                ForEach(rows) { row in
                    timelineRow(row)
                }
            }
        }
    }

    private func timelineRow(_ row: EventRow) -> some View {
        let dotColor = Self.tagColors[row.tagIndex % Self.tagColors.count]
        return HStack(alignment: .top, spacing: 0) {
            // Timeline dot + line
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.skeinCream)
                    .overlay(Circle().strokeBorder(dotColor, lineWidth: 2))
                    .frame(width: 11, height: 11)
                    .padding(.top, 6)
                Rectangle()
                    .fill(Color.skeinHairline)
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 11)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(row.event.timestamp.formatted(.dateTime.month(.abbreviated).day().hour().minute()).uppercased())
                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.skeinMuted)
                        .kerning(1.4)
                    Text(row.tagLabel.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(dotColor)
                        .kerning(1)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.skeinCream2)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                let note = row.event.noteContent
                Text(note.isEmpty ? "(no notes)" : note)
                    .font(.system(size: 13.5))
                    .foregroundStyle(note.isEmpty ? Color.skeinMuted : Color.skeinInk)
                    .italic(note.isEmpty)
                    .lineLimit(3)

                if let elapsed = row.elapsedText, !elapsed.isEmpty {
                    Text("\(elapsed) SINCE LAST")
                        .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.skeinMuted)
                        .kerning(0.6)
                }
            }
            .padding(.leading, 11)
            .padding(.bottom, 14)
        }
    }
}
