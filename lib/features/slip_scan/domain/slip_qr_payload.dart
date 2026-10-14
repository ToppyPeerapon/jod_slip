/// The mini-QR printed on Thai bank transfer slips (Bank of Thailand
/// slip-verification format).
///
/// It is an EMVCo-style TLV string (2-digit tag, 2-digit length, value):
///   00 → nested { 00: API id, 01: sending bank code, 02: transaction ref }
///   51 → country code ("TH")
///   91 → CRC
///
/// Note it does not carry the amount; that still comes from OCR.
class SlipQrPayload {
  const SlipQrPayload({required this.sendingBankCode, required this.transactionRef});

  final String sendingBankCode;
  final String transactionRef;

  static SlipQrPayload? tryParse(String raw) {
    final root = _parseTlv(raw.trim());
    final nested = root?['00'];
    if (nested == null) return null;

    final inner = _parseTlv(nested);
    final bankCode = inner?['01'];
    final ref = inner?['02'];
    if (bankCode == null || ref == null || ref.isEmpty) return null;

    return SlipQrPayload(sendingBankCode: bankCode, transactionRef: ref);
  }

  /// Returns null when [input] is not a well-formed TLV sequence.
  static Map<String, String>? _parseTlv(String input) {
    final fields = <String, String>{};
    var i = 0;
    while (i < input.length) {
      if (i + 4 > input.length) return null;
      final tag = input.substring(i, i + 2);
      final length = int.tryParse(input.substring(i + 2, i + 4));
      if (length == null || i + 4 + length > input.length) return null;
      fields[tag] = input.substring(i + 4, i + 4 + length);
      i += 4 + length;
    }
    return Map.unmodifiable(fields);
  }
}
