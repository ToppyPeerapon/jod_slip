/// Parses slip date/time strings such as:
///   "12 ต.ค. 69 14:30 น."     (KBank, 2-digit Buddhist year)
///   "12 ต.ค. 2569 - 14:30"    (SCB, 4-digit Buddhist year)
///   "12 ตุลาคม 2569"          (full Thai month name)
///   "12 Oct 2026 14:30:05"    (English slips)
///   "12/10/2569 14:30"        (numeric)
class ThaiDateParser {
  const ThaiDateParser._();

  static const _thaiMonths = <String, int>{
    'มกราคม': 1, 'กุมภาพันธ์': 2, 'มีนาคม': 3, 'เมษายน': 4,
    'พฤษภาคม': 5, 'มิถุนายน': 6, 'กรกฎาคม': 7, 'สิงหาคม': 8,
    'กันยายน': 9, 'ตุลาคม': 10, 'พฤศจิกายน': 11, 'ธันวาคม': 12,
    'ม.ค.': 1, 'ก.พ.': 2, 'มี.ค.': 3, 'เม.ย.': 4, 'พ.ค.': 5, 'มิ.ย.': 6,
    'ก.ค.': 7, 'ส.ค.': 8, 'ก.ย.': 9, 'ต.ค.': 10, 'พ.ย.': 11, 'ธ.ค.': 12,
  };

  static const _englishMonths = <String, int>{
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  /// Each Thai month abbreviation as a pattern tolerant of OCR dropping
  /// dots or inserting spaces ("ต.ค." / "ต.ค" / "ตค" / "ต. ค.").
  static final List<(RegExp, int)> _thaiMonthPatterns = [
    for (final entry in _thaiMonths.entries)
      (RegExp(_tolerantPattern(entry.key)), entry.value),
  ];

  static final _englishDate = RegExp(
    r'(?<!\d)(\d{1,2})\s*(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?,?\s*(\d{2,4})(?!\d)',
    caseSensitive: false,
  );

  static final _numericDate = RegExp(r'(?<!\d)(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})(?!\d)');

  static final _time = RegExp(r'(?<![\d.,])([01]?\d|2[0-3])[:.]([0-5]\d)(?:[:.]([0-5]\d))?(?![\d.,])');

  static final _colonTime = RegExp(r'(?<!\d)([01]?\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?(?!\d)');

  static String _tolerantPattern(String month) {
    final parts = month.split('.').where((p) => p.isNotEmpty).toList();
    final body = parts.map(RegExp.escape).join(r'\s*\.?\s*');
    return '(?<!\\d)(\\d{1,2})\\s*$body\\.?\\s*(\\d{2,4})(?!\\d)';
  }

  /// Finds the first date in [lines] and the time printed next to it.
  static DateTime? parse(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final date = _findDate(lines[i]);
      if (date == null) continue;

      final rest = lines[i].substring(date.end);
      final next = i + 1 < lines.length ? lines[i + 1] : '';
      final time = _findTime(rest, _time) ?? _findTime(next, _colonTime) ?? _findTimeAnywhere(lines);
      return _build(date, time);
    }
    return null;
  }

  static _DateMatch? _findDate(String line) {
    _DateMatch? best;
    void consider(_DateMatch? candidate) {
      if (candidate != null && (best == null || candidate.start < best!.start)) {
        best = candidate;
      }
    }

    for (final (pattern, month) in _thaiMonthPatterns) {
      final m = pattern.firstMatch(line);
      if (m != null) {
        consider(_DateMatch(int.parse(m[1]!), month, int.parse(m[2]!), m.start, m.end));
      }
    }

    final en = _englishDate.firstMatch(line);
    if (en != null) {
      final month = _englishMonths[en[2]!.toLowerCase()]!;
      consider(_DateMatch(int.parse(en[1]!), month, int.parse(en[3]!), en.start, en.end));
    }

    final numeric = _numericDate.firstMatch(line);
    if (numeric != null) {
      consider(_DateMatch(
        int.parse(numeric[1]!),
        int.parse(numeric[2]!),
        int.parse(numeric[3]!),
        numeric.start,
        numeric.end,
      ));
    }
    return best;
  }

  static (int, int, int)? _findTime(String text, RegExp pattern) {
    final m = pattern.firstMatch(text);
    if (m == null) return null;
    return (int.parse(m[1]!), int.parse(m[2]!), int.tryParse(m[3] ?? '') ?? 0);
  }

  /// Only colon-separated times are trusted away from the date line, so
  /// amounts like "0.00" are never mistaken for a time.
  static (int, int, int)? _findTimeAnywhere(List<String> lines) {
    for (final line in lines) {
      final time = _findTime(line, _colonTime);
      if (time != null) return time;
    }
    return null;
  }

  static DateTime? _build(_DateMatch date, (int, int, int)? time) {
    final year = normalizeYear(date.year);
    final (hour, minute, second) = time ?? (0, 0, 0);
    final result = DateTime(year, date.month, date.day, hour, minute, second);
    // Reject overflowed dates such as 31 Feb, which DateTime silently rolls over.
    if (result.month != date.month || result.day != date.day) return null;
    return result;
  }

  /// Converts 2/4-digit Buddhist or Gregorian years to a Gregorian year.
  ///
  /// Two-digit years >= 50 are Buddhist (69 → 2569 BE → 2026), others are
  /// Gregorian (26 → 2026). Four-digit years above 2400 are Buddhist.
  static int normalizeYear(int year) {
    if (year < 100) return year >= 50 ? 2500 + year - 543 : 2000 + year;
    if (year > 2400) return year - 543;
    return year;
  }
}

class _DateMatch {
  const _DateMatch(this.day, this.month, this.year, this.start, this.end);

  final int day;
  final int month;
  final int year;
  final int start;
  final int end;
}
