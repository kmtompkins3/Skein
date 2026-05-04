import SwiftUI
import SwiftData

struct TagsTabView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var context
    @State private var showingAddSheet = false
    @State private var tagToEdit: Tag?

    private var sortedTags: [Tag] {
        project.tags.sorted { $0.firstWriteAt < $1.firstWriteAt }
    }

    var body: some View {
        List {
            if project.tags.isEmpty {
                ContentUnavailableView(
                    "No Tags Yet",
                    systemImage: "tag",
                    description: Text("Tap Add Tag to link an NFC clip.")
                )
            } else {
                ForEach(Array(sortedTags.enumerated()), id: \.element.id) { index, tag in
                    TagRowView(tag: tag, label: "Tag \(index + 1)") {
                        tagToEdit = tag
                    }
                }
                .onDelete(perform: deleteTags)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button { showingAddSheet = true } label: {
                Label("Add Tag", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            WriteTagView(mode: .add(project: project))
        }
        .sheet(item: $tagToEdit) { tag in
            WriteTagView(mode: .update(tag: tag, project: project))
        }
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            context.delete(sortedTags[index])
        }
    }
}

struct TagRowView: View {
    let tag: Tag
    let label: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label).font(.headline)
                Text(tag.notes.isEmpty ? "(no notes)" : tag.notes)
                    .font(.subheadline).foregroundStyle(.secondary)
                    .lineLimit(2)
                Text("Last write: \(tag.lastWriteAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))")
                    .font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
