import Foundation
import UIKit

enum SnackPhotoStore {
    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = base.appendingPathComponent("SnackPhotos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static func fileURL(for snackID: UUID) -> URL {
        directoryURL.appendingPathComponent("\(snackID.uuidString).jpg")
    }

    static func save(image: UIImage, snackID: UUID) throws {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        try data.write(to: fileURL(for: snackID), options: .atomic)
    }

    static func load(snackID: UUID) -> UIImage? {
        let url = fileURL(for: snackID)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        return image
    }

    static func delete(snackID: UUID) {
        try? FileManager.default.removeItem(at: fileURL(for: snackID))
    }
}
