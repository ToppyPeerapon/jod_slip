import 'package:flutter/services.dart';

final _amountPattern = RegExp(r'^\d+(\.\d{0,2})?$');

/// Parses user-entered baht ("1,500", "89.5", "1500.25") into satang.
/// Returns null for empty or malformed input.
int? parseBahtToSatang(String input) {
  final cleaned = input.replaceAll(',', '').trim();
  if (cleaned.isEmpty || !_amountPattern.hasMatch(cleaned)) return null;
  final [baht, ...rest] = cleaned.split('.');
  final fraction = rest.isEmpty ? '' : rest.first;
  return int.parse(baht) * 100 + int.parse(fraction.padRight(2, '0'));
}

/// Formats satang for an editable text field ("1500.00" → "1500", "89.50").
String satangToInput(int satang) {
  if (satang <= 0) return '';
  final baht = satang ~/ 100;
  final fraction = satang % 100;
  return fraction == 0 ? '$baht' : '$baht.${fraction.toString().padLeft(2, '0')}';
}

/// Allows digits, commas and at most two decimal places while typing.
class AmountInputFormatter extends TextInputFormatter {
  static final _typing = RegExp(r'^[\d,]*(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return _typing.hasMatch(newValue.text) ? newValue : oldValue;
  }
}
