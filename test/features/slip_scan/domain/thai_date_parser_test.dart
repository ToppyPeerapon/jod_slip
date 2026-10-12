import 'package:flutter_test/flutter_test.dart';
import 'package:jod_slip/features/slip_scan/domain/thai_date_parser.dart';

void main() {
  group('ThaiDateParser.parse', () {
    final cases = <String, DateTime>{
      '12 ต.ค. 69 14:30 น.': DateTime(2026, 10, 12, 14, 30),
      '1 ม.ค. 2569 - 00:01': DateTime(2026, 1, 1, 0, 1),
      '5 มี.ค. 69 08:15': DateTime(2026, 3, 5, 8, 15),
      '31 ธ.ค. 68 23:59:59': DateTime(2025, 12, 31, 23, 59, 59),
      '12 ตุลาคม 2569 10:00': DateTime(2026, 10, 12, 10),
      '12 ตค 69 14:30': DateTime(2026, 10, 12, 14, 30),
      '12 ต. ค. 69 14.30 น.': DateTime(2026, 10, 12, 14, 30),
      '12 Oct 2026 14:30': DateTime(2026, 10, 12, 14, 30),
      '12 October 2026': DateTime(2026, 10, 12),
      '12/10/2569 14:30': DateTime(2026, 10, 12, 14, 30),
    };

    cases.forEach((input, expected) {
      test(input, () => expect(ThaiDateParser.parse([input]), expected));
    });

    test('takes the time from the next line when not on the date line', () {
      expect(ThaiDateParser.parse(['12 ต.ค. 69', '14:30 น.']), DateTime(2026, 10, 12, 14, 30));
    });

    test('does not mistake an amount for a time', () {
      expect(ThaiDateParser.parse(['12 ต.ค. 69', '0.00 บาท']), DateTime(2026, 10, 12));
    });

    test('distinguishes ม.ค. from มี.ค.', () {
      expect(ThaiDateParser.parse(['5 มี.ค. 69'])!.month, 3);
      expect(ThaiDateParser.parse(['5 ม.ค. 69'])!.month, 1);
    });

    test('rejects impossible dates', () {
      expect(ThaiDateParser.parse(['31 ก.พ. 69']), isNull);
    });

    test('returns null when no date exists', () {
      expect(ThaiDateParser.parse(['โอนเงินสำเร็จ']), isNull);
    });
  });

  group('ThaiDateParser.normalizeYear', () {
    test('two-digit Buddhist year', () => expect(ThaiDateParser.normalizeYear(69), 2026));
    test('two-digit Gregorian year', () => expect(ThaiDateParser.normalizeYear(26), 2026));
    test('four-digit Buddhist year', () => expect(ThaiDateParser.normalizeYear(2569), 2026));
    test('four-digit Gregorian year', () => expect(ThaiDateParser.normalizeYear(2026), 2026));
  });
}
