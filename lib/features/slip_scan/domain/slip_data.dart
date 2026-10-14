import '../../../core/institution/institution.dart';

/// Structured data extracted from a transfer slip.
///
/// Every field is optional because OCR can miss any of them; the user
/// reviews the result before it is saved.
class SlipData {
  const SlipData({
    this.amountSatang,
    this.dateTime,
    this.senderName,
    this.receiverName,
    this.senderInstitution,
    this.receiverInstitution,
    this.reference,
    this.rawText = '',
  });

  /// Amount in satang (1 baht = 100 satang) to avoid floating-point money.
  final int? amountSatang;
  final DateTime? dateTime;
  final String? senderName;
  final String? receiverName;

  /// Bank or wallet the money left from.
  final Institution? senderInstitution;

  /// Bank, PromptPay or wallet the money went to.
  final Institution? receiverInstitution;

  /// Transaction reference, used to detect slips imported twice.
  final String? reference;
  final String rawText;

  bool get hasAmount => amountSatang != null;
}
