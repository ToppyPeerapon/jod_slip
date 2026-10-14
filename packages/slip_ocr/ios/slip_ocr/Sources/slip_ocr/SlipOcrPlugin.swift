import Flutter
import UIKit

/// Method channel entry point: slip OCR plus photo-library access.
public class SlipOcrPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "slip_ocr", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(SlipOcrPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]

    switch call.method {
    case "recognize":
      guard let path = args["path"] as? String else { return result(missing("path")) }
      runInBackground(result) {
        guard let image = UIImage(contentsOfFile: path) else {
          throw SlipOcrError.message("Cannot load image at \(path)")
        }
        return try VisionRecognizer.recognize(image: image, level: .accurate)
      }

    case "requestPhotoAccess":
      PhotoLibrary.requestAccess { status in DispatchQueue.main.async { result(status) } }

    case "listImageAssets":
      let sinceMs = (args["sinceMs"] as? NSNumber)?.doubleValue
      runInBackground(result) { PhotoLibrary.listImageAssets(sinceMs: sinceMs) }

    case "quickScanAsset":
      guard let id = args["id"] as? String else { return result(missing("id")) }
      runInBackground(result) {
        let image = try PhotoLibrary.loadImage(id: id, maxDimension: PhotoLibrary.quickScanDimension)
        return try VisionRecognizer.recognize(image: image, level: .fast)
      }

    case "exportAsset":
      guard let id = args["id"] as? String else { return result(missing("id")) }
      runInBackground(result) { try PhotoLibrary.export(id: id) }

    case "openAppSettings":
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
      }
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func runInBackground(_ result: @escaping FlutterResult, _ work: @escaping () throws -> Any) {
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let payload = try work()
        DispatchQueue.main.async { result(payload) }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "failed", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private func missing(_ name: String) -> FlutterError {
    FlutterError(code: "invalid_args", message: "Missing '\(name)' argument", details: nil)
  }
}
