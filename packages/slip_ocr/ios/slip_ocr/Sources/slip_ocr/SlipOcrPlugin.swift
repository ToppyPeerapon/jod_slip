import Flutter
import UIKit
import Vision

/// Recognises text (Thai + English) and QR codes in slip images with Apple
/// Vision, entirely on-device.
public class SlipOcrPlugin: NSObject, FlutterPlugin {
  private static let preferredLanguages = ["th-TH", "en-US"]

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "slip_ocr", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(SlipOcrPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "recognize" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
      result(FlutterError(code: "invalid_args", message: "Missing 'path' argument", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let payload = try Self.recognize(path: path)
        DispatchQueue.main.async { result(payload) }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "recognition_failed", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private static func recognize(path: String) throws -> [String: Any] {
    guard let image = UIImage(contentsOfFile: path), let cgImage = image.cgImage else {
      throw NSError(
        domain: "slip_ocr", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Cannot load image at \(path)"])
    }

    let textRequest = VNRecognizeTextRequest()
    textRequest.recognitionLevel = .accurate
    // Language correction "fixes" account numbers and references, so keep it off.
    textRequest.usesLanguageCorrection = false
    textRequest.recognitionLanguages = supportedLanguages(for: textRequest)

    let barcodeRequest = VNDetectBarcodesRequest()
    barcodeRequest.symbologies = [.qr]

    #if targetEnvironment(simulator)
      // The simulator has no Neural Engine/GPU path for Vision ("Could not
      // create inference context"); real devices are unaffected.
      try useCPUOnly(textRequest)
      try useCPUOnly(barcodeRequest)
    #endif

    let handler = VNImageRequestHandler(
      cgImage: cgImage, orientation: CGImagePropertyOrientation(image.imageOrientation), options: [:])
    try handler.perform([textRequest, barcodeRequest])

    let blocks: [[String: Any]] = (textRequest.results ?? []).compactMap { observation in
      guard let candidate = observation.topCandidates(1).first else { return nil }
      // Vision boxes are normalised with a bottom-left origin; flip to top-left.
      let box = observation.boundingBox
      return [
        "text": candidate.string,
        "left": Double(box.minX),
        "top": Double(1 - box.maxY),
        "width": Double(box.width),
        "height": Double(box.height),
      ]
    }
    let barcodes = (barcodeRequest.results ?? []).compactMap { $0.payloadStringValue }

    return ["blocks": blocks, "barcodes": barcodes]
  }

  private static func useCPUOnly(_ request: VNRequest) throws {
    if #available(iOS 17.0, *) {
      for (stage, devices) in try request.supportedComputeStageDevices {
        if let cpu = devices.first(where: { if case .cpu = $0 { return true } else { return false } }) {
          request.setComputeDevice(cpu, for: stage)
        }
      }
    } else {
      request.usesCPUOnly = true
    }
  }

  /// Thai text recognition needs a recent iOS; fall back to English otherwise.
  private static func supportedLanguages(for request: VNRecognizeTextRequest) -> [String] {
    let supported = (try? request.supportedRecognitionLanguages()) ?? []
    let available = preferredLanguages.filter { supported.contains($0) }
    return available.isEmpty ? ["en-US"] : available
  }
}

extension CGImagePropertyOrientation {
  init(_ orientation: UIImage.Orientation) {
    switch orientation {
    case .up: self = .up
    case .upMirrored: self = .upMirrored
    case .down: self = .down
    case .downMirrored: self = .downMirrored
    case .left: self = .left
    case .leftMirrored: self = .leftMirrored
    case .right: self = .right
    case .rightMirrored: self = .rightMirrored
    @unknown default: self = .up
    }
  }
}
