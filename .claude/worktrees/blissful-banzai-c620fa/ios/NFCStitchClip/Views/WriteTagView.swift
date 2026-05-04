import SwiftUI
import SwiftData

enum WriteTagMode {
    case add(project: Project)
    case update(tag: Tag, project: Project)

    var initialNotes: String {
        if case .update(let tag, _) = self { return tag.notes }
        return ""
    }

    var title: String {
        if case .update = self { return "Edit Tag" }
        return "Add Tag"
    }

    var project: Project {
        switch self {
        case .add(let p):        return p
        case .update(_, let p): return p
        }
    }
}

struct WriteTagView: View {
    let mode: WriteTagMode
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss
    @StateObject private var nfc = NFCService()

    @State private var notes         = ""
    @State private var statusMessage = ""
    @State private var writeError:   String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Notes")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.horizontal)

                TextEditor(text: $notes)
                    .frame(minHeight: 120)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3))
                    )
                    .padding(.horizontal)

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(statusMessage.hasPrefix("✓") ? Color.green : Color.secondary)
                        .padding(.horizontal)
                }

                Spacer()

                Button(action: writeTag) {
                    HStack {
                        Image(systemName: "wave.3.right")
                        Text(nfc.isSessionActive ? "Hold iPhone near tag…" : "Write to Tag")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(nfc.isSessionActive ? Color.secondary : Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .disabled(nfc.isSessionActive)
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { notes = mode.initialNotes }
            .alert("Write Failed", isPresented: .constant(writeError != nil), presenting: writeError) { _ in
                Button("OK") { writeError = nil }
            } message: { msg in
                Text(msg)
            }
        }
    }

    private func writeTag() {
        let payload = NFCTagPayload(
            projectId: mode.project.id.uuidString,
            notes: notes,
            timestamp: Date.now.timeIntervalSince1970
        )
        statusMessage = "Hold iPhone near tag…"

        nfc.writeTag(payload: payload) { result in
            switch result {
            case .success:
                commitWrite()
                statusMessage = "✓ Tag written successfully"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { dismiss() }
            case .failure(let error):
                statusMessage = ""
                writeError = error.localizedDescription
            }
        }
    }

    /// Persists the tag write to SwiftData only after confirmed NFC success.
    private func commitWrite() {
        switch mode {
        case .add(let project):
            let tag = Tag(notes: notes)
            project.tags.append(tag)

        case .update(let tag, _):
            tag.notes        = notes
            tag.lastWriteAt  = .now
            tag.writeEvents.append(WriteEvent(noteContent: notes))
        }
    }
}
