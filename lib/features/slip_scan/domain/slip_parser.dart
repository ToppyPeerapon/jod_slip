import '../../../core/institution/institution.dart';
import 'slip_data.dart';
import 'slip_parties.dart';
import 'slip_qr_payload.dart';
import 'thai_date_parser.dart';

/// Turns OCR lines (and any QR payloads) from a Thai transfer slip into
/// [SlipData]. Pure Dart so it can be unit-tested without a device.
class SlipParser {
  const SlipParser._();

  static final _amountLabel = RegExp(r'(จำนวนเงิน|จำนวน|ยอดเงิน|ยอดโอน|ยอดชำระ|amount)', caseSensitive: false);
  static final _excludedAmountLine = RegExp(r'(ค่าธรรมเนียม|คงเหลือ|fee|balance)', caseSensitive: false);
  static final _currencyHint = RegExp(r'(บาท|thb|฿)', caseSensitive: false);
  static final _money = RegExp(r'(?<![\d.,])(\d{1,3}(?:,\d{3})+|\d+)\.(\d{2})(?![\d])');

  static final _referenceLabel = RegExp(
    r'(เลขที่รายการ|รหัสอ้างอิง|เลขที่อ้างอิง|หมายเลขอ้างอิง|รหัสรายการ|transaction\s*id|ref(?:erence)?(?:\s*no)?\.?)',
    caseSensitive: false,
  );

  /// Alphanumeric, optionally dashed (e.g. UUIDs from wallet apps).
  static final _referenceValue = RegExp(r'[A-Za-z0-9][A-Za-z0-9-]{9,}');

  static SlipData parse({required List<String> lines, List<String> qrCodes = const []}) {
    final cleaned = lines.map(_normaliseSpaces).where((l) => l.isNotEmpty).toList(growable: false);
    final rawText = cleaned.join('\n');
    final qr = qrCodes.map(SlipQrPayload.tryParse).whereType<SlipQrPayload>().firstOrNull;
    final parties = SlipParties.find(cleaned);

    return SlipData(
      amountSatang: _findAmount(cleaned),
      dateTime: ThaiDateParser.parse(cleaned),
      senderName: parties.senderName,
      receiverName: parties.receiverName,
      senderInstitution:
          Institution.fromCode(qr?.sendingBankCode) ?? parties.senderInstitution ?? Institution.detect(rawText),
      receiverInstitution: parties.receiverInstitution,
      reference: qr?.transactionRef ?? _findReference(cleaned),
      rawText: rawText,
    );
  }

  // ---------------------------------------------------------------- amount

  static int? _findAmount(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final label = _amountLabel.firstMatch(line);
      if (label == null || _excludedAmountLine.hasMatch(line)) continue;

      final sameLine = _firstMoney(line.substring(label.end));
      if (sameLine != null) return sameLine;
      if (i + 1 < lines.length && !_excludedAmountLine.hasMatch(lines[i + 1])) {
        final nextLine = _firstMoney(lines[i + 1]);
        if (nextLine != null) return nextLine;
      }
    }
    return _largestMoney(lines, requireCurrency: true) ?? _largestMoney(lines, requireCurrency: false);
  }

  static int? _largestMoney(List<String> lines, {required bool requireCurrency}) {
    final candidates = [
      for (final line in lines)
        if (!_excludedAmountLine.hasMatch(line) && (!requireCurrency || _currencyHint.hasMatch(line)))
          ..._money.allMatches(line).map(_toSatang),
    ].where((v) => v > 0);
    if (candidates.isEmpty) return null;
    return candidates.reduce((a, b) => a > b ? a : b);
  }

  static int? _firstMoney(String text) {
    final match = _money.firstMatch(text);
    return match == null ? null : _toSatang(match);
  }

  static int _toSatang(RegExpMatch match) {
    final baht = int.parse(match[1]!.replaceAll(',', ''));
    return baht * 100 + int.parse(match[2]!);
  }

  // ------------------------------------------------------------- reference

  static String? _findReference(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final label = _referenceLabel.firstMatch(lines[i]);
      if (label == null) continue;

      final sameLine = _referenceValue.firstMatch(lines[i].substring(label.end));
      if (sameLine != null) return sameLine[0];
      if (i + 1 < lines.length) {
        final nextLine = _referenceValue.firstMatch(lines[i + 1]);
        if (nextLine != null) return nextLine[0];
      }
    }
    return null;
  }

  static String _normaliseSpaces(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();
}
