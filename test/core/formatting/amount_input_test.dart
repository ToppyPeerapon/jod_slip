import 'package:flutter_test/flutter_test.dart';
import 'package:jod_slip/core/formatting/amount_input.dart';

void main() {
  group('parseBahtToSatang', () {
    final cases = <String, int?>{
      '1500': 150000,
      '1,500': 150000,
      '89.5': 8950,
      '89.05': 8905,
      '0.01': 1,
      ' 12 ': 1200,
      '': null,
      'abc': null,
      '1.234': null,
      '1.2.3': null,
    };
    cases.forEach((input, expected) {
      test('"$input" → $expected', () => expect(parseBahtToSatang(input), expected));
    });
  });

  group('satangToInput', () {
    test('whole baht', () => expect(satangToInput(150000), '1500'));
    test('with satang', () => expect(satangToInput(8905), '89.05'));
    test('zero is empty', () => expect(satangToInput(0), ''));
  });
}
