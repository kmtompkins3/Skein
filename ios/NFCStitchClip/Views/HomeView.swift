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
            Text("Skein")
                .font(Font.custom("Helvetica Neue", size: 20).weight(.bold))
                .foregroundStyle(Color.skeinCharcoal)
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
            Text("PROJECTS · \(projects.count) ACTIVE")
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

    private var streakStrip: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("THIS WEEK")
                    .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.skeinCream2.opacity(0.7))
                    .kerning(1.8)
                Text("4 days · 6h 12m on the needles")
                    .font(Font.custom("Helvetica Neue", size: 15).weight(.semibold))
                    .foregroundStyle(Color.skeinCream)
            }
            Spacer()
            // Mini bar chart
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array([12, 22, 18, 28, 8, 24, 14].enumerated()), id: \.offset) { i, h in
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
