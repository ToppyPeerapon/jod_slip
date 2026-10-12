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
  Future<SlipOcrResult> recognize(String imagePath) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>('recognize', {'path': imagePath});
    if (result == null) {
      throw PlatformException(code: 'empty_result', message: 'Native OCR returned no result');
    }
    return SlipOcrResult.fromMap(result);
  }
}
