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
    @State private var scanResult: TagScanResult?
    @State private var orphanedPayload: NFCTagPayload?
    @State private var readError: String?

    var body: some View {
        NavigationStack {
            List {
                if projects.isEmpty {
                    ContentUnavailableView(
                        "No Projects Yet",
                        systemImage: "tray",
                        description: Text("Tap + to create your first project.")
                    )
                } else {
                    ForEach(projects) { project in
                        NavigationLink(destination: ProjectDetailView(project: project)) {
                            ProjectRowView(project: project)
                        }
                    }
                    .onDelete(perform: deleteProjects)
                }
            }
            .navigationTitle("Stitch Clip")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: scanTag) {
                        Label("Scan Tag", systemImage: "wave.3.right")
                    }
                    .disabled(nfc.isSessionActive)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingCreateProject = true } label: {
                        Label("New Project", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateProject) {
                CreateProjectView()
            }
            .sheet(item: $scanResult) { result in
                ScanResultModal(project: result.project, payload: result.payload)
            }
            .sheet(item: $orphanedPayload) { payload in
                OrphanedTagModal(payload: payload)
            }
            .alert("Scan Failed", isPresented: .constant(readError != nil), presenting: readError) { _ in
                Button("OK") { readError = nil }
            } message: { msg in
                Text(msg)
            }
        }
    }

    private func scanTag() {
        nfc.readTag { result in
            switch result {
            case .success(let payload):
                if let project = projects.first(where: { $0.id.uuidString == payload.projectId }) {
                    scanResult = TagScanResult(project: project, payload: payload)
                } else {
                    orphanedPayload = payload
                }
            case .failure(let error):
                readError = error.localizedDescription
            }
        }
    }

    private func deleteProjects(at offsets: IndexSet) {
        for index in offsets {
            let project = projects[index]
            if let path = project.imagePath {
                ImageStorageService.shared.delete(filename: path)
            }
            context.delete(project)
        }
    }
}
