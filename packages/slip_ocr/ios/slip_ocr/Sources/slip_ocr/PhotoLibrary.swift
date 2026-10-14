import Photos
import UIKit

/// Read-only access to the user's photo library for finding slips.
enum PhotoLibrary {
  /// Size used for the quick "is this a slip?" pass; small keeps it fast.
  static let quickScanDimension: CGFloat = 1200

  /// Size of exported images for full OCR; large enough for small text.
  static let exportDimension: CGFloat = 2400

  static func requestAccess(_ completion: @escaping (String) -> Void) {
    PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
      completion(name(of: status))
    }
  }

  /// Image assets newest first, optionally only those created since [sinceMs].
  static func listImageAssets(sinceMs: Double?) -> [[String: Any]] {
    let options = PHFetchOptions()
    options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    if let sinceMs {
      let since = Date(timeIntervalSince1970: sinceMs / 1000) as NSDate
      options.predicate = NSPredicate(
        format: "mediaType == %d AND creationDate >= %@", PHAssetMediaType.image.rawValue, since)
    } else {
      options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
    }

    let result = PHAsset.fetchAssets(with: options)
    var assets: [[String: Any]] = []
    assets.reserveCapacity(result.count)
    result.enumerateObjects { asset, _, _ in
      assets.append([
        "id": asset.localIdentifier,
        "createdMs": (asset.creationDate?.timeIntervalSince1970 ?? 0) * 1000,
      ])
    }
    return assets
  }

  /// Loads a local copy of the photo. iCloud-only photos are skipped rather
  /// than downloaded, so scanning never uses mobile data.
  static func loadImage(id: String, maxDimension: CGFloat) throws -> UIImage {
    guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject else {
      throw SlipOcrError.message("Photo not found")
    }
    let options = PHImageRequestOptions()
    options.isSynchronous = true
    options.deliveryMode = .highQualityFormat
    options.resizeMode = .fast
    options.isNetworkAccessAllowed = false

    var image: UIImage?
    PHImageManager.default().requestImage(
      for: asset, targetSize: CGSize(width: maxDimension, height: maxDimension),
      contentMode: .aspectFit, options: options
    ) { result, _ in image = result }

    guard let image else { throw SlipOcrError.message("Photo is not available on this device") }
    return image
  }

  /// Writes the photo to a temporary JPEG and returns its path.
  static func export(id: String) throws -> String {
    let image = try loadImage(id: id, maxDimension: exportDimension)
    guard let data = image.jpegData(compressionQuality: 0.9) else {
      throw SlipOcrError.message("Could not encode photo")
    }
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("library_\(UUID().uuidString).jpg")
    try data.write(to: url)
    return url.path
  }

  private static func name(of status: PHAuthorizationStatus) -> String {
    switch status {
    case .authorized: return "authorized"
    case .limited: return "limited"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "notDetermined"
    @unknown default: return "denied"
    }
  }
}
