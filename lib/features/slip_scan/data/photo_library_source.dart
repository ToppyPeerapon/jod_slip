import 'package:slip_ocr/slip_ocr.dart';

import '../domain/text_line_grouper.dart';
import 'slip_recognizer.dart';

export 'package:slip_ocr/slip_ocr.dart' show PhotoAccess, PhotoAsset;

/// The device photo library. Abstracted so the library scan can be tested
/// without the native plugin.
abstract interface class PhotoLibrarySource {
  Future<PhotoAccess> requestAccess();

  /// Image assets newest first, optionally only those created since [since].
  Future<List<PhotoAsset>> listImages({DateTime? since});

  /// Cheap English-only OCR + QR read on a downscaled copy.
  Future<RecognizedSlip> quickScan(String assetId);

  /// Copies the photo to a temporary file for full OCR and returns its path.
  Future<String> export(String assetId);

  Future<void> openSettings();
}

class NativePhotoLibrarySource implements PhotoLibrarySource {
  const NativePhotoLibrarySource([this._ocr = const SlipOcr()]);

  final SlipOcr _ocr;

  @override
  Future<PhotoAccess> requestAccess() => _ocr.requestPhotoAccess();

  @override
  Future<List<PhotoAsset>> listImages({DateTime? since}) => _ocr.listImageAssets(since: since);

  @override
  Future<RecognizedSlip> quickScan(String assetId) async {
    final result = await _ocr.quickScanAsset(assetId);
    final blocks = result.blocks
        .map((b) => OcrBlock(text: b.text, left: b.left, top: b.top, width: b.width, height: b.height))
        .toList(growable: false);
    return RecognizedSlip(lines: groupIntoLines(blocks), qrCodes: result.barcodes);
  }

  @override
  Future<String> export(String assetId) => _ocr.exportAsset(assetId);

  @override
  Future<void> openSettings() => _ocr.openAppSettings();
}
