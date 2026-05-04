import SwiftUI
import SwiftData

struct OrphanedTagModal: View {
    let payload: NFCTagPayload
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss
    @Query(sort: \Project.startDate, order: .reverse) private var projects: [Project]
    @StateObject private var nfc = NFCService()

    @State private var showingPicker  = false
    @State private var linkError:     String?
    @State private var successMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tag not linked to a project")
                    .font(.title2).bold()

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes on tag:").font(.caption).foregroundStyle(.secondary)
                    Text(payload.notes.isEmpty ? "(no notes)" : payload.notes).font(.body)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Last written:").font(.caption).foregroundStyle(.secondary)
                    Text(payload.firstWriteDate.formatted(
                        .dateTime.month(.abbreviated).day().year().hour().minute()
                    )).font(.body)
                }

                Spacer()

                if let msg = successMessage {
                    Text(msg).foregroundStyle(.green).font(.subheadline)
                }
                if let err = linkError {
                    Text(err).foregroundStyle(.red).font(.caption)
                }

                VStack(spacing: 12) {
                    Button { showingPicker = true } label: {
                        Text("Link to a Project")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(nfc.isSessionActive ? Color.secondary : Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(nfc.isSessionActive)

                    Button("Dismiss") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .sheet(isPresented: $showingPicker) {
                ProjectPickerView(projects: projects) { selectedProject in
                    linkTag(to: selectedProject)
                }
            }
        }
    }

    private func linkTag(to project: Project) {
        linkError = nil
        let newPayload = NFCTagPayload(
            projectId: project.id.uuidString,
            notes: payload.notes,
            timestamp: Date.now.timeIntervalSince1970
        )
        nfc.writeTag(payload: newPayload) { result in
            switch result {
            case .success:
                // Preserve firstWriteAt from the tag's original timestamp
                let tag = Tag(notes: payload.notes, firstWriteAt: payload.firstWriteDate)
                project.tags.append(tag)
                successMessage = "✓ Tag linked to \(project.name)"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
            case .failure(let error):
                // No partial state — tag is not added to project
                linkError = error.localizedDescription
            }
        }
    }
}

struct ProjectPickerView: View {
    let projects: [Project]
    let onSelect: (Project) -> Void
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss
    @State private var showingCreate = false

    var body: some View {
        NavigationStack {
            List {
                Button {
                    showingCreate = true
                } label: {
                    Label("Create New Project…", systemImage: "plus.circle")
                }
                .foregroundStyle(.accentColor)

                ForEach(projects) { project in
                    Button(project.name) {
                        onSelect(project)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Link to Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateProjectView()
            }
        }
    }
}
