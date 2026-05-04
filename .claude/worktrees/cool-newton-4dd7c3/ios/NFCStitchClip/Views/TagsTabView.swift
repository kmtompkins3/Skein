import SwiftUI
import SwiftData

struct TagsTabView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var context
    @State private var showingAddSheet = false
    @State private var tagToEdit: Tag?

    private static let tagColors: [Color] = [
        .skeinTangerine, .skeinMint, .skeinChampagne, .skeinPink,
        Color(red: 0.49, green: 0.68, blue: 0.79), Color(red: 0.72, green: 0.66, blue: 0.60),
    ]

    private var sortedTags: [Tag] {
        project.tags.sorted { $0.firstWriteAt < $1.firstWriteAt }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(spacing: 8) {
                    if project.tags.isEmpty {
                        emptyState
                    } else {
                        ForEach(Array(sortedTags.enumerated()), id: \.element.id) { index, tag in
                            TagRowView(
                                tag: tag,
                                label: "Tag \(index + 1)",
                                number: index + 1,
                                color: Self.tagColors[index % Self.tagColors.count],
                                isRecent: index == sortedTags.count - 1 && sortedTags.count > 1
                            ) {
                                tagToEdit = tag
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    context.delete(tag)
                                } label: {
                                    Label("Delete Tag", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .background(Color.skeinCream)

            // Floating CTA
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.skeinCream.opacity(0), Color.skeinCream],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 20)

                SkeinButton(label: "Add Tag", icon: "wave.3.right", style: .tangerine) {
                    showingAddSheet = true
                }
                .disabled(false)
                .padding(.horizontal, 22)
                .padding(.bottom, 28)
                .background(Color.skeinCream)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            WriteTagView(mode: .add(project: project))
        }
        .sheet(item: $tagToEdit) { tag in
            WriteTagView(mode: .update(tag: tag, project: project))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tag")
                .font(.system(size: 32))
                .foregroundStyle(Color.skeinMuted)
            Text("No Tags Yet")
                .font(Font.custom("Helvetica Neue", size: 17).weight(.semibold))
                .foregroundStyle(Color.skeinCharcoal)
            Text("Tap Add Tag to link an NFC clip.")
                .font(.system(size: 13))
                .foregroundStyle(Color.skeinMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct TagRowView: View {
    let tag:      Tag
    let label:    String
    let number:   Int
    let color:    Color
    var isRecent: Bool = false
    let onTap:    () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                TagNumberBadge(number: number, color: color)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(label)
                            .font(Font.custom("Helvetica Neue", size: 14).weight(.semibold))
                            .foregroundStyle(Color.skeinCharcoal)
                        if isRecent {
                            Text("NEW")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.skeinCream)
                                .kerning(1.6)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.skeinTangerine)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        Spacer()
                        Text("\(tag.writeEvents.count) ✕")
                            .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color.skeinMuted)
                            .kerning(0.6)
                    }

                    Text(tag.notes.isEmpty ? "(no notes)" : tag.notes)
                        .font(.system(size: 13))
                        .foregroundStyle(tag.notes.isEmpty ? Color.skeinMuted : Color.skeinInk)
                        .italic(tag.notes.isEmpty)
                        .lineLimit(2)

                    Text(tag.lastWriteAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()).uppercased())
                        .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.skeinMuted)
                        .kerning(0.6)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.skeinCream)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.skeinHairline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
