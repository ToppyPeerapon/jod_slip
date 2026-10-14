import '../data/slip_recognizer.dart';
import 'slip_qr_payload.dart';

final _money = RegExp(r'(?<![\d.,])\d{1,3}(?:,\d{3})*\.\d{2}(?!\d)');

/// Masked account / wallet numbers: "xxx-x-x3206-x", "x-xxxx-xxxx7-91-5",
/// "**** ******* 6431".
final _maskedNumber = RegExp(r'([xX*]{1,4}-[xX\d*]+-[xX\d*]+|\*{3,}\s*\*{3,})');

final _slipWords = RegExp(
  r'(successful|transfer|transaction|reference|ref\s*no|amount|promptpay|wallet)',
  caseSensitive: false,
);

/// Cheap first-pass check on a fast (English-only) OCR of a photo: is it
/// worth running full Thai OCR to read it as a slip?
///
/// True for a slip verification QR, or an amount next to a masked account
/// number or typical slip wording. Errs towards false positives: the user
/// reviews every draft, while a missed slip is silently lost.
bool looksLikeSlip(RecognizedSlip quick) {
  if (quick.qrCodes.any((code) => SlipQrPayload.tryParse(code) != null)) return true;

  final text = quick.lines.join('\n');
  return _money.hasMatch(text) && (_maskedNumber.hasMatch(text) || _slipWords.hasMatch(text));
}
