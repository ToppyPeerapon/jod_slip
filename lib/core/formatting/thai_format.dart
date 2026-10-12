import 'package:intl/intl.dart';

/// Locale-aware formatting. Thai output uses the Buddhist calendar year
/// (Gregorian + 543), which is what Thai users expect.
class AppFormat {
  const AppFormat(this.locale);

  final String locale;

  static const buddhistEraOffset = 543;

  bool get _isThai => locale == 'th';

  int displayYear(DateTime date) => _isThai ? date.year + buddhistEraOffset : date.year;

  /// "฿1,500.00", or "+฿1,500.00" / "-฿1,500.00" when [signed].
  String baht(int satang, {bool signed = false}) {
    final formatted = NumberFormat.currency(locale: locale, symbol: '฿', decimalDigits: 2)
        .format(satang.abs() / 100);
    if (!signed || satang == 0) return satang < 0 ? '-$formatted' : formatted;
    return satang > 0 ? '+$formatted' : '-$formatted';
  }

  /// "ตุลาคม 2569" / "October 2026"
  String monthYear(DateTime date) => '${DateFormat.MMMM(locale).format(date)} ${displayYear(date)}';

  /// "จ. 12 ต.ค. 2569" / "Mon, 12 Oct 2026"
  String dayHeader(DateTime date) {
    final day = _isThai
        ? DateFormat('E d MMM', locale).format(date)
        : DateFormat('E, d MMM', locale).format(date);
    return '$day ${displayYear(date)}';
  }

  /// "12 ต.ค. 2569 14:30"
  String dateTime(DateTime date) =>
      '${DateFormat('d MMM', locale).format(date)} ${displayYear(date)} ${time(date)}';

  String time(DateTime date) => DateFormat.Hm(locale).format(date);
}
