import SwiftUI
import SwiftData
import PhotosUI

struct CreateProjectView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @State private var name         = ""
    @State private var patternLink  = ""
    @State private var pickerItem:  PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var linkInvalid  = false

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Name (required)", text: $name)

                    TextField("Pattern link (optional)", text: $patternLink)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .onChange(of: patternLink) {
                            linkInvalid = !patternLink.isEmpty && URL(string: patternLink) == nil
                        }

                    if linkInvalid {
                        Label("Enter a valid URL", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption).foregroundStyle(.yellow)
                    }
                }

                Section("Image (optional)") {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable().scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: 180)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Label("Choose Photo", systemImage: "photo.badge.plus")
                        }
                    }
                    .onChange(of: pickerItem) { loadPhoto() }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: createProject)
                        .disabled(!canCreate)
                }
            }
        }
    }

    private func loadPhoto() {
        Task {
            guard let data = try? await pickerItem?.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
            else { return }
            await MainActor.run { selectedImage = image }
        }
    }

    private func createProject() {
        var imagePath: String?
        if let image = selectedImage {
            imagePath = try? ImageStorageService.shared.save(image)
        }
        let project = Project(
            name: name.trimmingCharacters(in: .whitespaces),
            patternLink: patternLink.isEmpty ? nil : patternLink,
            imagePath: imagePath
        )
        context.insert(project)
        dismiss()
    }
}
