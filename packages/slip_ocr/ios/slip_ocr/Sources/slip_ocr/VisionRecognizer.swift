import UIKit
import Vision

/// Text and QR recognition with Apple Vision, entirely on-device.
enum VisionRecognizer {
  /// `.accurate` reads Thai + English for parsing; `.fast` (English only) is a
  /// cheap first pass used to decide whether a photo looks like a slip.
  static func recognize(image: UIImage, level: VNRequestTextRecognitionLevel) throws -> [String: Any] {
    guard let cgImage = image.cgImage else {
      throw SlipOcrError.message("Image has no bitmap data")
    }

    let textRequest = VNRecognizeTextRequest()
    textRequest.recognitionLevel = level
    // Language correction "fixes" account numbers and references, so keep it off.
    textRequest.usesLanguageCorrection = false
    textRequest.recognitionLanguages = level == .accurate ? supportedLanguages(for: textRequest) : ["en-US"]

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

  private static let preferredLanguages = ["th-TH", "en-US"]

  /// Thai text recognition needs a recent iOS; fall back to English otherwise.
  private static func supportedLanguages(for request: VNRecognizeTextRequest) -> [String] {
    let supported = (try? request.supportedRecognitionLanguages()) ?? []
    let available = preferredLanguages.filter { supported.contains($0) }
    return available.isEmpty ? ["en-US"] : available
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
}

enum SlipOcrError: LocalizedError {
  case message(String)

  var errorDescription: String? {
    switch self {
    case .message(let text): return text
    }
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
