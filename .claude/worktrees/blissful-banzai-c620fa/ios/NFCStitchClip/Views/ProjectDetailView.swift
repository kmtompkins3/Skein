import SwiftUI

struct ProjectDetailView: View {
    @Bindable var project: Project
    @State private var selectedTab     = 0
    @State private var showCompleteAlert = false

    var body: some View {
        VStack(spacing: 0) {
            projectHeader
                .padding()

            Picker("Tab", selection: $selectedTab) {
                Text("Tags").tag(0)
                Text("History").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            if selectedTab == 0 {
                TagsTabView(project: project)
            } else {
                HistoryTabView(project: project)
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Menu {
                Button(project.isCompleted ? "Mark as Ongoing" : "Mark as Complete") {
                    showCompleteAlert = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
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

    @ViewBuilder
    private var projectHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            if let path = project.imagePath,
               let image = ImageStorageService.shared.load(filename: path) {
                Image(uiImage: image)
                    .resizable().scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 6) {
                if project.isCompleted {
                    Label("Completed", systemImage: "checkmark.seal.fill")
                        .font(.caption).foregroundStyle(.green)
                }
                if let link = project.patternLink, let url = URL(string: link) {
                    Link(destination: url) {
                        Label("View Pattern", systemImage: "link")
                            .font(.subheadline)
                    }
                }
            }
            Spacer()
        }
    }

    private func toggleCompletion() {
        project.isCompleted.toggle()
        project.endDate = project.isCompleted ? .now : nil
    }
}
