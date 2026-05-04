import SwiftUI

struct ScanResultModal: View {
    let project: Project
    let payload: NFCTagPayload
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let path = project.imagePath,
                       let image = ImageStorageService.shared.load(filename: path) {
                        Image(uiImage: image)
                            .resizable().scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 180)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(project.name).font(.title2).bold()
                        if let link = project.patternLink, let url = URL(string: link) {
                            Link(destination: url) {
                                Label(link, systemImage: "link")
                                    .font(.caption).lineLimit(1)
                            }
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes on tag:")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(payload.notes.isEmpty ? "(no notes)" : payload.notes)
                            .font(.body)
                    }

                    Spacer(minLength: 24)

                    NavigationLink(destination: ProjectDetailView(project: project)) {
                        Text("Open Project")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .simultaneousGesture(TapGesture().onEnded { dismiss() })

                    Button("Dismiss") { dismiss() }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Tag Found")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") { dismiss() }
                }
            }
        }
    }
}
