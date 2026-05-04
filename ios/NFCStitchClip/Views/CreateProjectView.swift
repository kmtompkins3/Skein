import SwiftUI
import SwiftData
import PhotosUI

struct CreateProjectView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @State private var name           = ""
    @State private var patternLink    = ""
    @State private var pickerItem:    PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var linkInvalid    = false
    @State private var selectedSwatch = 0

    private let swatches: [Color] = [
        .skeinTangerine, .skeinMint, .skeinChampagne, .skeinPink,
        Color(red: 0.49, green: 0.68, blue: 0.79), Color(red: 0.72, green: 0.66, blue: 0.60),
    ]

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.skeinCream.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        headline
                        photoAndName
                        swatchPicker
                        detailsSection
                        tip
                    }
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.skeinMuted)
                }
                ToolbarItem(placement: .principal) {
                    Text("NEW PROJECT")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.skeinMuted)
                        .kerning(2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: createProject)
                        .font(Font.custom("Helvetica Neue", size: 14).weight(.semibold))
                        .foregroundStyle(canCreate ? Color.skeinTangerine : Color.skeinMuted)
                        .disabled(!canCreate)
                }
            }
        }
    }

    // MARK: Subviews

    private var headline: some View {
        Text("What are you\nmaking?")
            .font(Font.custom("Helvetica Neue", size: 28).weight(.bold))
            .foregroundStyle(Color.skeinCharcoal)
            .tracking(-0.7)
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 18)
    }

    private var photoAndName: some View {
        HStack(alignment: .top, spacing: 14) {
            // Photo well
            PhotosPicker(selection: $pickerItem, matching: .images) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable().scaledToFill()
                        .frame(width: 92, height: 92)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.skeinCream2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .strokeBorder(Color.skeinHairline, style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                            )
                        VStack(spacing: 4) {
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.skeinMuted)
                            Text("PHOTO")
                                .font(.system(size: 8.5, weight: .regular, design: .monospaced))
                                .foregroundStyle(Color.skeinMuted)
                                .kerning(1.6)
                        }
                    }
                    .frame(width: 92, height: 92)
                }
            }
            .onChange(of: pickerItem) { loadPhoto() }

            // Name + pattern fields
            VStack(spacing: 8) {
                fieldCard(label: "NAME") {
                    TextField("Required", text: $name)
                        .font(Font.custom("Helvetica Neue", size: 15).weight(.semibold))
                        .foregroundStyle(Color.skeinCharcoal)
                        .autocorrectionDisabled()
                }
                fieldCard(label: "PATTERN URL") {
                    TextField("ravelry.com/…", text: $patternLink)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.skeinMuted)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .onChange(of: patternLink) {
                            linkInvalid = !patternLink.isEmpty && URL(string: patternLink) == nil
                        }
                    if linkInvalid {
                        Text("Enter a valid URL")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.skeinTangerine)
                    }
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 18)
    }

    private func fieldCard<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.skeinMuted)
                .kerning(1.6)
            content()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.skeinCream)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.skeinHairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var swatchPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("COLOR TAG")
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.skeinMuted)
                .kerning(1.8)
                .padding(.horizontal, 24)

            HStack(spacing: 10) {
                ForEach(swatches.indices, id: \.self) { i in
                    ZStack {
                        Circle()
                            .fill(swatches[i])
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        selectedSwatch == i ? Color.skeinCharcoal : Color.skeinHairline,
                                        lineWidth: selectedSwatch == i ? 2.5 : 1
                                    )
                            )
                            .shadow(color: selectedSwatch == i ? Color.skeinCream : .clear, radius: 0, x: 0, y: 0)
                        if selectedSwatch == i {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.skeinCream)
                        }
                    }
                    .onTapGesture { selectedSwatch = i }
                }
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 18)
    }

    private var detailsSection: some View {
        let rows: [(String, String)] = [
            ("Weight",       "Worsted"),
            ("Needles",      "4 mm · US 6"),
            ("Yardage goal", "1,200 yd"),
            ("Started",      Date.now.formatted(.dateTime.month(.abbreviated).day().year())),
        ]

        return VStack(alignment: .leading, spacing: 0) {
            Text("DETAILS")
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.skeinMuted)
                .kerning(1.8)
                .padding(.horizontal, 24)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                    HStack {
                        Text(row.0)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.skeinCharcoal)
                        Spacer()
                        HStack(spacing: 4) {
                            Text(row.1)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.skeinMuted)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.skeinMuted.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.skeinCream)

                    if i < rows.count - 1 {
                        Divider()
                            .background(Color.skeinHairline)
                            .padding(.leading, 16)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.skeinHairline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 22)
        }
        .padding(.bottom, 18)
    }

    private var tip: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.skeinTangerine)
                .frame(width: 22, height: 22)
                .overlay(
                    Text("i")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.skeinCream)
                )
            Text("You can clip a Skein NFC tag to your project bag now or later — tags appear here once they're written.")
                .font(.system(size: 12))
                .foregroundStyle(Color.skeinInk)
                .lineSpacing(3)
        }
        .padding(14)
        .background(Color.skeinCream2)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 22)
    }

    // MARK: Actions

    private func loadPhoto() {
        Task {
            guard let data = try? await pickerItem?.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }
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
