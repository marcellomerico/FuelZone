import Foundation
import UIKit

/// Local photos for custom snacks (downscaled JPEGs + in-memory thumbnail cache).
enum SnackPhotoStore {
    private static let maxPixelSize: CGFloat = 600
    private static let cache = NSCache<NSUUID, UIImage>()

    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("SnackPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    static func fileURL(for snackID: UUID) -> URL {
        directoryURL.appendingPathComponent("\(snackID.uuidString).jpg")
    }

    static func save(image: UIImage, snackID: UUID) throws {
        let scaled = downscaled(image)
        guard let data = scaled.jpegData(compressionQuality: 0.82) else { return }
        try data.write(to: fileURL(for: snackID), options: .atomic)
        cache.setObject(scaled, forKey: snackID as NSUUID)
    }

    /// Cached image for list rows; reads from disk only once per snack.
    static func load(snackID: UUID) -> UIImage? {
        if let cached = cache.object(forKey: snackID as NSUUID) { return cached }
        let url = fileURL(for: snackID)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        cache.setObject(image, forKey: snackID as NSUUID)
        return image
    }

    static func delete(snackID: UUID) {
        cache.removeObject(forKey: snackID as NSUUID)
        try? FileManager.default.removeItem(at: fileURL(for: snackID))
    }

    private static func downscaled(_ image: UIImage) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxPixelSize else { return image }
        let scale = maxPixelSize / longest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
