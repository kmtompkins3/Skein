import UIKit
import Foundation

final class ImageStorageService {
    static let shared = ImageStorageService()
    private init() {}

    private var imagesDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir  = docs.appendingPathComponent("images", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Saves image as JPEG (0.7 quality). Returns the filename (UUID.jpg) to store in the model.
    func save(_ image: UIImage) throws -> String {
        let filename = "\(UUID().uuidString).jpg"
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: imagesDirectory.appendingPathComponent(filename))
        return filename
    }

    func load(filename: String) -> UIImage? {
        UIImage(contentsOfFile: imagesDirectory.appendingPathComponent(filename).path)
    }

    func delete(filename: String) {
        try? FileManager.default.removeItem(at: imagesDirectory.appendingPathComponent(filename))
    }
}
