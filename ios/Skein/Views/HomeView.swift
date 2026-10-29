import SwiftUI
import SwiftData

struct TagScanResult: Identifiable {
    let id = UUID()
    let project: Project
    let payload: NFCTagPayload
}

struct HomeView: View {
    @Query(sort: \Project.startDate, order: .reverse) private var projects: [Project]
    @Environment(\.modelContext) private var context
    @StateObject private var nfc = NFCService()

    @State private var showingCreateProject = false
    @State private var scanResult:    TagScanResult?
    @State private var orphanedPayload: NFCTagPayload?
    @State private var readError:     String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.skeinCream.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        headline
                        streakStrip
                        projectList
                    }
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingCreateProject) { CreateProjectView() }
            .sheet(item: $scanResult) { r in ScanResultModal(project: r.project, payload: r.payload) }
            .sheet(item: $orphanedPayload) { p in OrphanedTagModal(payload: p) }
            .alert("Read failed. Please try again.", isPresented: .constant(readError != nil)) {
                Button("OK") { readError = nil }
            }
        }
    }

    // MARK: Subviews

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: scanTag) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.skeinCharcoal)
                    .frame(width: 38, height: 38)
                    .background(Color.skeinCream2)
                    .clipShape(Circle())
            }
            .disabled(nfc.isSessionActive)
        }
        ToolbarItem(placement: .principal) {
            SkeinWordmark(size: 20)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showingCreateProject = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.skeinCream)
                    .frame(width: 38, height: 38)
                    .background(Color.skeinCharcoal)
                    .clipShape(Circle())
            }
        }
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROJECTS · \(projects.filter { !$0.isCompleted }.count) ACTIVE")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.skeinMuted)
                .kerning(2)

            Text("Tap. Track.\nStitch.")
                .font(Font.custom("Helvetica Neue", size: 36).weight(.bold))
                .foregroundStyle(Color.skeinCharcoal)
                .lineSpacing(2)
                .tracking(-0.9)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    /// Work time per calendar day for the last 7 days (oldest first), using the 12-hour session-gap rule.
    private var weekWork: [TimeInterval] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var buckets = [TimeInterval](repeating: 0, count: 7)
        for project in projects {
            let events = project.allWriteEvents.sorted { $0.timestamp < $1.timestamp }
            guard events.count > 1 else { continue }
            for i in 1..<events.count {
                let gap = events[i].timestamp.timeIntervalSince(events[i - 1].timestamp)
                guard gap <= 12 * 3600 else { continue }
                let day = cal.startOfDay(for: events[i].timestamp)
                let offset = cal.dateComponents([.day], from: day, to: today).day ?? 99
                if (0..<7).contains(offset) { buckets[6 - offset] += gap }
            }
        }
        return buckets
    }

    private var weekSummary: String {
        let days = weekWork.filter { $0 > 0 }.count
        let mins = Int(weekWork.reduce(0, +) / 60)
        guard mins > 0 else { return "No stitching logged yet" }
        let time = mins >= 60 ? "\(mins / 60)h \(mins % 60)m" : "\(mins)m"
        return "\(days) day\(days == 1 ? "" : "s") · \(time) on the needles"
    }

    private var weekBarHeights: [CGFloat] {
        let peak = max(weekWork.max() ?? 0, 1)
        return weekWork.map { CGFloat(6 + 22 * ($0 / peak)) }
    }

    private var streakStrip: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("THIS WEEK")
                    .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.skeinCream2.opacity(0.7))
                    .kerning(1.8)
                Text(weekSummary)
                    .font(Font.custom("Helvetica Neue", size: 15).weight(.semibold))
                    .foregroundStyle(Color.skeinCream)
            }
            Spacer()
            // Mini bar chart
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(weekBarHeights.enumerated()), id: \.offset) { i, h in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i == 6 ? Color.skeinTangerine : Color.skeinCream2.opacity(0.55))
                        .frame(width: 5, height: CGFloat(h))
                }
            }
            .frame(height: 28)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.skeinCharcoal)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 22)
        .padding(.bottom, 16)
    }

    private var projectList: some View {
        LazyVStack(spacing: 10) {
            if projects.isEmpty {
                emptyState
            } else {
                ForEach(projects) { project in
                    NavigationLink(destination: ProjectDetailView(project: project)) {
                        ProjectRowView(project: project)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) { deleteProject(project) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 22)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "scissors")
                .font(.system(size: 36))
                .foregroundStyle(Color.skeinMuted)
            Text("No Projects Yet")
                .font(Font.custom("Helvetica Neue", size: 18).weight(.semibold))
                .foregroundStyle(Color.skeinCharcoal)
            Text("Tap + to start your first project.")
                .font(.system(size: 14))
                .foregroundStyle(Color.skeinMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: Actions

    private func scanTag() {
        nfc.readTag { result in
            switch result {
            case .success(let payload):
                if let project = projects.first(where: { $0.id.uuidString == payload.projectId }) {
                    scanResult = TagScanResult(project: project, payload: payload)
                } else {
                    orphanedPayload = payload
                }
            case .failure:
                readError = "Read failed. Please try again."
            }
        }
    }

    private func deleteProject(_ project: Project) {
        if let path = project.imagePath {
            ImageStorageService.shared.delete(filename: path)
        }
        context.delete(project)
    }
}
