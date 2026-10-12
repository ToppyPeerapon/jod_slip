import '../../../core/bank/thai_bank.dart';
import 'slip_data.dart';
import 'slip_qr_payload.dart';
import 'thai_date_parser.dart';

/// Turns OCR lines (and any QR payloads) from a Thai transfer slip into
/// [SlipData]. Pure Dart so it can be unit-tested without a device.
class SlipParser {
  const SlipParser._();

  static final _amountLabel = RegExp(
    r'(จำนวนเงิน|จำนวน|ยอดเงิน|ยอดโอน|ยอดชำระ|amount)',
    caseSensitive: false,
  );
  static final _excludedAmountLine = RegExp(
    r'(ค่าธรรมเนียม|คงเหลือ|fee|balance)',
    caseSensitive: false,
  );
  static final _currencyHint = RegExp(r'(บาท|thb|฿)', caseSensitive: false);
  static final _money = RegExp(r'(?<![\d.,])(\d{1,3}(?:,\d{3})+|\d+)\.(\d{2})(?![\d])');

  static final _referenceLabel = RegExp(
    r'(เลขที่รายการ|รหัสอ้างอิง|เลขที่อ้างอิง|หมายเลขอ้างอิง|รหัสรายการ|transaction\s*id|ref(?:erence)?(?:\s*no)?\.?)',
    caseSensitive: false,
  );
  static final _referenceValue = RegExp(r'[A-Za-z0-9]{10,}');

  static final _fromLabel = RegExp(r'^\s*(จาก|from)\s*:?\s*(.*)$', caseSensitive: false);
  static final _toLabel = RegExp(r'^\s*(ไปยัง|ถึง|ไป|ผู้รับ|to)\s*:?\s*(.*)$', caseSensitive: false);

  /// Name prefixes (titles and company forms). "นางสาว" must precede "นาง".
  static final _namePrefix = RegExp(
    r'^\s*(นางสาว|นาง|นาย|น\.ส\.|ด\.ช\.|ด\.ญ\.|mrs\.?|mr\.?|ms\.?|miss|บจก\.?|บมจ\.?|หจก\.?|บริษัท|ร้าน)',
    caseSensitive: false,
  );
  static final _accountNumber = RegExp(r'[xX\d*]{3}-[xX\d*]-[xX\d*]{4,5}-[xX\d*]');

  static SlipData parse({required List<String> lines, List<String> qrCodes = const []}) {
    final cleaned = lines.map(_normaliseSpaces).where((l) => l.isNotEmpty).toList(growable: false);
    final rawText = cleaned.join('\n');
    final qr = qrCodes.map(SlipQrPayload.tryParse).whereType<SlipQrPayload>().firstOrNull;
    final (sender, receiver) = _findParties(cleaned);

    return SlipData(
      amountSatang: _findAmount(cleaned),
      dateTime: ThaiDateParser.parse(cleaned),
      senderName: sender,
      receiverName: receiver,
      bank: ThaiBank.fromCode(qr?.sendingBankCode) ?? ThaiBank.detect(rawText),
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

  // --------------------------------------------------------------- parties

  /// Labelled slips ("จาก" / "ไปยัง") are read directly. Unlabelled slips
  /// (e.g. K PLUS) list the sender first and receiver second, so the first
  /// two titled names are used instead.
  static (String?, String?) _findParties(List<String> lines) {
    final labelledSender = _findLabelledName(lines, _fromLabel);
    final labelledReceiver = _findLabelledName(lines, _toLabel);
    final titled = lines.where(_namePrefix.hasMatch).map(_cleanName).toList(growable: false);

    final sender = labelledSender ?? titled.firstOrNull;
    final receiver = labelledReceiver ?? titled.where((n) => n != sender).firstOrNull;
    return (sender, receiver);
  }

  static String? _findLabelledName(List<String> lines, RegExp label) {
    for (var i = 0; i < lines.length; i++) {
      final match = label.firstMatch(lines[i]);
      if (match == null) continue;

      final rest = _cleanName(match[2] ?? '');
      if (_looksLikeName(rest)) return rest;
      for (final candidate in lines.skip(i + 1).take(2)) {
        final name = _cleanName(candidate);
        if (_looksLikeName(name)) return name;
      }
    }
    return null;
  }

  static bool _looksLikeName(String text) {
    if (text.length < 2) return false;
    if (_namePrefix.hasMatch(text)) return true;
    final digits = text.replaceAll(RegExp(r'\D'), '').length;
    return digits * 2 < text.length && ThaiBank.detect(text) == null;
  }

  static String _cleanName(String text) =>
      _normaliseSpaces(text.replaceAll(_accountNumber, ''));

  static String _normaliseSpaces(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();
}
