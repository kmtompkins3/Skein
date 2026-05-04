import SwiftUI
import SwiftData

struct OrphanedTagModal: View {
    let payload: NFCTagPayload
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss
    @Query(sort: \Project.startDate, order: .reverse) private var projects: [Project]
    @StateObject private var nfc = NFCService()

    @State private var showingPicker   = false
    @State private var linkError:      String?
    @State private var successMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.skeinCream.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TAG NOT LINKED")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.skeinMuted)
                            .kerning(2)
                        Text("Tag not linked\nto a project")
                            .font(Font.custom("Helvetica Neue", size: 28).weight(.bold))
                            .foregroundStyle(Color.skeinCharcoal)
                            .tracking(-0.7)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .padding(.bottom, 20)

                    // Note card
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NOTES ON TAG")
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color.skeinMuted)
                            .kerning(1.6)
                        Text(payload.notes.isEmpty ? "(no notes)" : payload.notes)
                            .font(.system(size: 15))
                            .foregroundStyle(payload.notes.isEmpty ? Color.skeinMuted : Color.skeinInk)
                            .italic(payload.notes.isEmpty)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.skeinCream)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.skeinHairline, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 22)
                    .padding(.bottom, 12)

                    // Timestamp
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text("Last written \(payload.firstWriteDate.formatted(.dateTime.month(.abbreviated).day().year().hour().minute()))")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(Color.skeinMuted)
                    .padding(.horizontal, 24)

                    Spacer()

                    // Feedback messages
                    if let msg = successMessage {
                        Text(msg)
                            .font(Font.custom("Helvetica Neue", size: 15).weight(.semibold))
                            .foregroundStyle(Color.skeinTangerine)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 8)
                    }
                    if let err = linkError {
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 8)
                    }

                    // CTAs
                    VStack(spacing: 8) {
                        SkeinButton(label: "Link to a Project", icon: "link", style: .tangerine) {
                            showingPicker = true
                        }
                        .disabled(nfc.isSessionActive)
                        .opacity(nfc.isSessionActive ? 0.6 : 1)

                        Button("Dismiss") { dismiss() }
                            .font(Font.custom("Helvetica Neue", size: 14).weight(.medium))
                            .foregroundStyle(Color.skeinMuted)
                            .frame(height: 48)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 28)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") { dismiss() }
                        .foregroundStyle(Color.skeinMuted)
                }
            }
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
                let tag = Tag(notes: payload.notes, firstWriteAt: payload.firstWriteDate)
                project.tags.append(tag)
                successMessage = "✓ Tag linked to \(project.name)"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
            case .failure:
                linkError = "Write failed. Please try again."
            }
        }
    }
}

struct ProjectPickerView: View {
    let projects:  [Project]
    let onSelect:  (Project) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingCreate = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.skeinCream.ignoresSafeArea()
                List {
                    Button {
                        showingCreate = true
                    } label: {
                        Label("Create New Project…", systemImage: "plus.circle")
                            .foregroundStyle(Color.skeinTangerine)
                    }
                    .listRowBackground(Color.skeinCream)

                    ForEach(projects) { project in
                        Button(project.name) {
                            onSelect(project)
                            dismiss()
                        }
                        .foregroundStyle(Color.skeinCharcoal)
                        .listRowBackground(Color.skeinCream)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Link to Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.skeinMuted)
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateProjectView()
            }
        }
    }
}
