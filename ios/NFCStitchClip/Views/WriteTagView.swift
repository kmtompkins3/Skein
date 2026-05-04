import SwiftUI
import SwiftData

enum WriteTagMode {
    case add(project: Project)
    case update(tag: Tag, project: Project)

    var initialNotes: String {
        if case .update(let tag, _) = self { return tag.notes }
        return ""
    }

    var project: Project {
        switch self {
        case .add(let p):        return p
        case .update(_, let p): return p
        }
    }

    var tagLabel: String {
        if case .update(let tag, let project) = self {
            let sorted = project.tags.sorted { $0.firstWriteAt < $1.firstWriteAt }
            if let idx = sorted.firstIndex(where: { $0.id == tag.id }) {
                return "TAG \(String(format: "%02d", idx + 1))"
            }
        }
        return "NEW TAG"
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

    private let maxChars = 200

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.skeinCream.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(mode.project.name.uppercased()) · \(mode.tagLabel)")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color.skeinMuted)
                            .kerning(1.8)
                        Text("What did you\njust finish?")
                            .font(Font.custom("Helvetica Neue", size: 28).weight(.bold))
                            .foregroundStyle(Color.skeinCharcoal)
                            .tracking(-0.7)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                    // Note card
                    VStack(alignment: .leading, spacing: 0) {
                        TextEditor(text: $notes)
                            .font(.system(size: 15))
                            .foregroundStyle(Color.skeinCharcoal)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .frame(minHeight: 120)
                            .onChange(of: notes) {
                                if notes.count > maxChars {
                                    notes = String(notes.prefix(maxChars))
                                }
                            }

                        Divider().background(Color.skeinHairline)
                            .padding(.bottom, 12)

                        HStack(alignment: .center) {
                            // Quick-add chips
                            HStack(spacing: 6) {
                                ForEach(["+ ROW CT", "+ STITCH", "+ PHOTO"], id: \.self) { chip in
                                    Text(chip)
                                        .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                                        .foregroundStyle(Color.skeinMuted)
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Color.skeinCream2)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                            Spacer()
                            Text("\(notes.count) / \(maxChars)")
                                .font(.system(size: 10, weight: .regular, design: .monospaced))
                                .foregroundStyle(Color.skeinMuted)
                        }
                    }
                    .padding(18)
                    .background(Color.skeinCream)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(Color.skeinHairline, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 22)
                    .padding(.top, 18)

                    // NFC wave prompt
                    Spacer()
                    nfcPrompt
                    Spacer()

                    // Status / CTA
                    VStack(spacing: 8) {
                        if !statusMessage.isEmpty {
                            Text(statusMessage)
                                .font(Font.custom("Helvetica Neue", size: 15).weight(.semibold))
                                .foregroundStyle(statusMessage.hasPrefix("✓") ? Color.skeinTangerine : Color.skeinMuted)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        SkeinButton(
                            label: nfc.isSessionActive ? "Hold iPhone near the clip…" : "Write to Tag",
                            icon: "wave.3.right",
                            style: .charcoal,
                            action: writeTag
                        )
                        .disabled(nfc.isSessionActive)
                        .opacity(nfc.isSessionActive ? 0.6 : 1)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 28)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.skeinMuted)
                }
                ToolbarItem(placement: .principal) {
                    Text("EDIT TAG")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.skeinMuted)
                        .kerning(2)
                }
            }
            .onAppear { notes = mode.initialNotes }
            .alert("Write failed. Please try again.", isPresented: .constant(writeError != nil)) {
                Button("OK") { writeError = nil }
            }
        }
    }

    // MARK: NFC rings animation

    private var nfcPrompt: some View {
        VStack(spacing: 0) {
            ZStack {
                // Concentric rings
                ForEach([0, 1, 2], id: \.self) { r in
                    Circle()
                        .strokeBorder(
                            nfc.isSessionActive ? Color.skeinTangerine.opacity(0.6 - Double(r) * 0.18) : Color.skeinHairline,
                            lineWidth: 1
                        )
                        .frame(width: CGFloat(88 + r * 28 + 8), height: CGFloat(88 + r * 28 + 8))
                }
                // Core button
                Circle()
                    .fill(nfc.isSessionActive ? Color.skeinTangerine : Color.skeinCream2)
                    .frame(width: 88, height: 88)
                    .shadow(color: Color.skeinTangerine.opacity(nfc.isSessionActive ? 0.4 : 0), radius: 16, y: 8)
                    .overlay(
                        Image(systemName: "wave.3.right")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(nfc.isSessionActive ? Color.skeinCream : Color.skeinMuted)
                    )
            }
            .frame(width: 156, height: 156)

            Text(nfc.isSessionActive ? "SCANNING · NTAG216" : "READY · NTAG216")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.skeinMuted)
                .kerning(2)
                .padding(.top, 22)

            Text(nfc.isSessionActive ? "Hold your iPhone near the clip" : "Tap Write to start")
                .font(Font.custom("Helvetica Neue", size: 17).weight(.semibold))
                .foregroundStyle(Color.skeinCharcoal)
                .tracking(-0.42)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.3), value: nfc.isSessionActive)
    }

    // MARK: Actions

    private func writeTag() {
        let payload = NFCTagPayload(
            projectId: mode.project.id.uuidString,
            notes: notes,
            timestamp: Date.now.timeIntervalSince1970
        )
        statusMessage = "Hold iPhone near the clip…"
        nfc.writeTag(payload: payload) { result in
            switch result {
            case .success:
                commitWrite()
                statusMessage = "✓ Tag written successfully"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { dismiss() }
            case .failure:
                statusMessage = ""
                writeError = "Write failed. Please try again."
            }
        }
    }

    private func commitWrite() {
        switch mode {
        case .add(let project):
            let tag = Tag(notes: notes)
            project.tags.append(tag)
        case .update(let tag, _):
            tag.notes       = notes
            tag.lastWriteAt = .now
            tag.writeEvents.append(WriteEvent(noteContent: notes))
        }
    }
}
