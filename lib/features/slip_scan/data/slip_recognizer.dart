import 'package:slip_ocr/slip_ocr.dart';

import '../domain/text_line_grouper.dart';

/// Raw recognition output for one slip image.
class RecognizedSlip {
  const RecognizedSlip({required this.lines, required this.qrCodes});

  final List<String> lines;
  final List<String> qrCodes;
}

/// Reads text and QR codes from a slip image. Abstracted so the import flow
/// can be tested without the native OCR plugin.
abstract interface class SlipRecognizer {
  Future<RecognizedSlip> recognize(String imagePath);
}

/// On-device recognition via the `slip_ocr` plugin (Apple Vision on iOS).
class NativeSlipRecognizer implements SlipRecognizer {
  const NativeSlipRecognizer([this._ocr = const SlipOcr()]);

  final SlipOcr _ocr;

  @override
  Future<RecognizedSlip> recognize(String imagePath) async {
    final result = await _ocr.recognize(imagePath);
    final blocks = result.blocks
        .map((b) => OcrBlock(text: b.text, left: b.left, top: b.top, width: b.width, height: b.height))
        .toList(growable: false);
    return RecognizedSlip(lines: groupIntoLines(blocks), qrCodes: result.barcodes);
  }
}
