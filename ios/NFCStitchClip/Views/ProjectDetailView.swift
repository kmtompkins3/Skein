import SwiftUI

struct ProjectDetailView: View {
    @Bindable var project: Project
    @State private var selectedTab     = 0
    @State private var showCompleteAlert = false

    private static let tagColors: [Color] = [
        .skeinTangerine, .skeinMint, .skeinChampagne, .skeinPink,
        Color(red: 0.49, green: 0.68, blue: 0.79), Color(red: 0.72, green: 0.66, blue: 0.60),
    ]

    private var thumbnailColor: Color {
        let colors = Self.tagColors
        return colors[abs(project.id.hashValue) % colors.count]
    }

    private var dayCount: Int {
        let secs = Date.now.timeIntervalSince(project.startDate)
        return max(1, Int(secs / 86400))
    }

    private var workHours: String {
        let secs = project.estimatedWorkTime
        guard secs > 0 else { return "–" }
        return String(format: "%.0fh", secs / 3600)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.skeinCream.ignoresSafeArea()

            VStack(spacing: 0) {
                hero
                statRow
                tabBar
                Divider().background(Color.skeinHairline)

                if selectedTab == 0 {
                    TagsTabView(project: project)
                } else {
                    HistoryTabView(project: project)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("PROJECT")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.skeinMuted)
                    .kerning(2)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(project.isCompleted ? "Mark as Ongoing" : "Mark as Complete") {
                        showCompleteAlert = true
                    }
                    if let link = project.patternLink, let url = URL(string: link) {
                        Link("View Pattern", destination: url)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.skeinCharcoal)
                        .frame(width: 38, height: 38)
                        .background(Color.skeinCream2)
                        .clipShape(Circle())
                }
            }
        }
        .alert(
            project.isCompleted ? "Mark as Ongoing?" : "Mark as Complete?",
            isPresented: $showCompleteAlert
        ) {
            Button(project.isCompleted ? "Mark Ongoing" : "Mark Complete") { toggleCompletion() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: Subviews

    private var hero: some View {
        HStack(alignment: .bottom, spacing: 16) {
            if let path = project.imagePath,
               let image = ImageStorageService.shared.load(filename: path) {
                Image(uiImage: image)
                    .resizable().scaledToFill()
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                YarnThumbnail(size: 84, color: thumbnailColor, label: project.isCompleted ? "DONE" : "WIP")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(project.startDate.formatted(.dateTime.month().year()))
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.skeinMuted)
                    .kerning(1.8)
                Text(project.name)
                    .font(Font.custom("Helvetica Neue", size: 26).weight(.bold))
                    .foregroundStyle(Color.skeinCharcoal)
                    .tracking(-0.65)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            }
            .padding(.bottom, 4)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    private var statRow: some View {
        HStack(spacing: 8) {
            StatPill(key: "TAPS", value: "\(project.allWriteEvents.count)")
            StatPill(key: "TIME", value: workHours)
            StatPill(key: "TAGS", value: "\(project.tags.count)")
            StatPill(key: "DAYS", value: "\(dayCount)")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 18)
    }

    private var tabBar: some View {
        HStack(spacing: 6) {
            tabButton(title: "Tags · \(project.tags.count)", index: 0)
            tabButton(title: "History", index: 1)
            Spacer()
            if let link = project.patternLink, let url = URL(string: link) {
                Link(destination: url) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.system(size: 11, weight: .medium))
                        Text("PATTERN")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .kerning(1.4)
                    }
                    .foregroundStyle(Color.skeinCharcoal)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.skeinCream2)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 14)
    }

    private func tabButton(title: String, index: Int) -> some View {
        Button { selectedTab = index } label: {
            Text(title)
                .font(Font.custom("Helvetica Neue", size: 13).weight(selectedTab == index ? .semibold : .medium))
                .foregroundStyle(selectedTab == index ? Color.skeinCream : Color.skeinMuted)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedTab == index ? Color.skeinCharcoal : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func toggleCompletion() {
        project.isCompleted.toggle()
        project.endDate = project.isCompleted ? .now : nil
    }
}
