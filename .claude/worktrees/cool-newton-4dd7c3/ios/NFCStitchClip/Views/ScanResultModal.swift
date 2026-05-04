import SwiftUI

struct ScanResultModal: View {
    let project: Project
    let payload: NFCTagPayload
    @Environment(\.dismiss) private var dismiss

    private static let tagColors: [Color] = [
        .skeinTangerine, .skeinMint, .skeinChampagne, .skeinPink,
        Color(red: 0.49, green: 0.68, blue: 0.79), Color(red: 0.72, green: 0.66, blue: 0.60),
    ]

    private var thumbnailColor: Color {
        let colors = Self.tagColors
        return colors[abs(project.id.hashValue) % colors.count]
    }

    private var workTimeText: String {
        let secs = project.estimatedWorkTime
        guard secs > 0 else { return "–" }
        let h = Int(secs / 3600)
        let m = Int((secs.truncatingRemainder(dividingBy: 3600)) / 60)
        if h == 0 { return "\(m)m" }
        return "\(h)h \(m)m"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed backdrop
            Color.skeinCharcoal.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Sheet
            VStack(alignment: .leading, spacing: 0) {
                // Drag handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.skeinHairline)
                    .frame(width: 36, height: 4)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)
                    .padding(.bottom, 14)

                // Success badge
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.skeinTangerine)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.skeinCream)
                        )
                    Text("TAG READ · 0.4S")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.skeinMuted)
                        .kerning(2)
                }
                .padding(.bottom, 18)

                // Project header
                HStack(spacing: 14) {
                    if let path = project.imagePath,
                       let image = ImageStorageService.shared.load(filename: path) {
                        Image(uiImage: image)
                            .resizable().scaledToFill()
                            .frame(width: 68, height: 68)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        YarnThumbnail(size: 68, color: thumbnailColor, label: "WIP")
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(project.name.uppercased())")
                            .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color.skeinMuted)
                            .kerning(1.8)
                            .lineLimit(1)
                        Text("Picked up\nwhere you left off.")
                            .font(Font.custom("Helvetica Neue", size: 22).weight(.bold))
                            .foregroundStyle(Color.skeinCharcoal)
                            .tracking(-0.55)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(.bottom, 16)

                // Last note quote
                VStack(alignment: .leading, spacing: 6) {
                    Text("LAST NOTE")
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.skeinMuted)
                        .kerning(1.6)
                    Text(payload.notes.isEmpty ? "(no notes)" : "\"\(payload.notes)\"")
                        .font(.system(size: 14))
                        .foregroundStyle(payload.notes.isEmpty ? Color.skeinMuted : Color.skeinInk)
                        .italic(payload.notes.isEmpty)
                        .lineLimit(3)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.skeinCream2)
                .overlay(
                    Rectangle()
                        .fill(Color.skeinTangerine)
                        .frame(width: 3)
                        .frame(maxHeight: .infinity),
                    alignment: .leading
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.bottom, 14)

                // Stats row
                HStack(spacing: 8) {
                    statChip(key: "SESSION", value: sessionTime)
                    statChip(key: "TOTAL",   value: workTimeText)
                    statChip(key: "TAPS",    value: "\(project.allWriteEvents.count)")
                }
                .padding(.bottom, 18)

                // Buttons
                NavigationLink(destination: WriteTagView(mode: .add(project: project))) {
                    HStack(spacing: 8) {
                        Image(systemName: "wave.3.right")
                            .font(.system(size: 16, weight: .medium))
                        Text("Write a new note")
                            .font(Font.custom("Helvetica Neue", size: 15).weight(.semibold))
                    }
                    .foregroundStyle(Color.skeinCream)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.skeinTangerine)
                    .clipShape(Capsule())
                    .shadow(color: Color.skeinTangerine.opacity(0.35), radius: 12, y: 6)
                }
                .simultaneousGesture(TapGesture().onEnded { dismiss() })

                NavigationLink(destination: ProjectDetailView(project: project)) {
                    Text("Open Project")
                        .font(Font.custom("Helvetica Neue", size: 14).weight(.medium))
                        .foregroundStyle(Color.skeinMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .simultaneousGesture(TapGesture().onEnded { dismiss() })
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
            .background(Color.skeinCream)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .ignoresSafeArea()
    }

    private var sessionTime: String {
        guard let lastEvent = project.allWriteEvents.sorted(by: { $0.timestamp < $1.timestamp }).dropLast().last else {
            return "–"
        }
        let gap = Date.now.timeIntervalSince(lastEvent.timestamp)
        if gap > 43200 { return "–" }
        if gap < 3600 { return "\(Int(gap / 60))m" }
        return String(format: "%.1fh", gap / 3600)
    }

    private func statChip(key: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(key)
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.skeinMuted)
                .kerning(1.4)
            Text(value)
                .font(Font.custom("Helvetica Neue", size: 17).weight(.semibold))
                .foregroundStyle(Color.skeinCharcoal)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.skeinCream2)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
