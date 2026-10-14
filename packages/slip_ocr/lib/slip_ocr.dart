import 'package:flutter/services.dart';

/// A piece of recognised text. The box is normalised to 0..1 with a
/// top-left origin, independent of image size.
class SlipOcrBlock {
  const SlipOcrBlock({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  factory SlipOcrBlock.fromMap(Map<Object?, Object?> map) => SlipOcrBlock(
        text: map['text']! as String,
        left: (map['left']! as num).toDouble(),
        top: (map['top']! as num).toDouble(),
        width: (map['width']! as num).toDouble(),
        height: (map['height']! as num).toDouble(),
      );

  final String text;
  final double left;
  final double top;
  final double width;
  final double height;
}

class SlipOcrResult {
  const SlipOcrResult({required this.blocks, required this.barcodes});

  factory SlipOcrResult.fromMap(Map<Object?, Object?> map) => SlipOcrResult(
        blocks: List.unmodifiable(
          (map['blocks'] as List<Object?>? ?? const [])
              .cast<Map<Object?, Object?>>()
              .map(SlipOcrBlock.fromMap),
        ),
        barcodes: List.unmodifiable((map['barcodes'] as List<Object?>? ?? const []).cast<String>()),
      );

  final List<SlipOcrBlock> blocks;

  /// Raw payloads of QR codes found in the image.
  final List<String> barcodes;
}

/// On-device text (Thai + English) and QR recognition for slip images.
///
/// iOS uses Apple Vision. Android is not implemented yet.
class SlipOcr {
  const SlipOcr();

  static const MethodChannel _channel = MethodChannel('slip_ocr');

  /// Recognises text and QR codes in the image file at [imagePath].
  ///
  /// Throws a [PlatformException] if the image cannot be read.
  Future<SlipOcrResult> recognize(String imagePath) =>
      _invokeResult('recognize', {'path': imagePath});

  /// Asks for read access to the whole photo library.
  Future<PhotoAccess> requestPhotoAccess() async {
    final status = await _channel.invokeMethod<String>('requestPhotoAccess');
    return PhotoAccess.values.asNameMap()[status] ?? PhotoAccess.denied;
  }

  /// Image assets in the library, newest first, optionally only those
  /// created on or after [since].
  Future<List<PhotoAsset>> listImageAssets({DateTime? since}) async {
    final assets = await _channel.invokeListMethod<Object?>(
      'listImageAssets',
      {if (since != null) 'sinceMs': since.millisecondsSinceEpoch},
    );
    return List.unmodifiable(
      (assets ?? const []).cast<Map<Object?, Object?>>().map(PhotoAsset.fromMap),
    );
  }

  /// Fast, English-only recognition on a downscaled copy of a library photo,
  /// used to decide cheaply whether it looks like a slip.
  Future<SlipOcrResult> quickScanAsset(String assetId) =>
      _invokeResult('quickScanAsset', {'id': assetId});

  /// Copies a library photo to a temporary JPEG and returns its path.
  Future<String> exportAsset(String assetId) async {
    final path = await _channel.invokeMethod<String>('exportAsset', {'id': assetId});
    if (path == null) throw PlatformException(code: 'empty_result', message: 'Export returned no path');
    return path;
  }

  /// Opens this app's page in the system Settings (to grant photo access).
  Future<void> openAppSettings() => _channel.invokeMethod<void>('openAppSettings');

  Future<SlipOcrResult> _invokeResult(String method, Map<String, Object?> args) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(method, args);
    if (result == null) {
      throw PlatformException(code: 'empty_result', message: 'Native OCR returned no result');
    }
    return SlipOcrResult.fromMap(result);
  }
}

/// Photo library permission. [limited] means the user picked which photos
/// the app may see.
enum PhotoAccess { authorized, limited, denied, restricted, notDetermined }

class PhotoAsset {
  const PhotoAsset({required this.id, required this.createdAt});

  factory PhotoAsset.fromMap(Map<Object?, Object?> map) => PhotoAsset(
        id: map['id']! as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch((map['createdMs']! as num).toInt()),
      );

  /// Platform identifier (PHAsset localIdentifier on iOS).
  final String id;
  final DateTime createdAt;
}
