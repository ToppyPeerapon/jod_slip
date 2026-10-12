import 'package:flutter_test/flutter_test.dart';
import 'package:jod_slip/features/slip_scan/domain/text_line_grouper.dart';

OcrBlock _block(String text, double left, double top, {double height = 0.03}) =>
    OcrBlock(text: text, left: left, top: top, width: 0.2, height: height);

void main() {
  test('joins blocks on the same row in left-to-right order', () {
    final lines = groupIntoLines([
      _block('1,500.00 บาท', 0.6, 0.501),
      _block('จำนวน:', 0.1, 0.5),
      _block('โอนเงินสำเร็จ', 0.3, 0.1),
    ]);

    expect(lines, ['โอนเงินสำเร็จ', 'จำนวน:  1,500.00 บาท']);
  });

  test('keeps blocks on different rows separate', () {
    final lines = groupIntoLines([
      _block('A', 0.1, 0.10),
      _block('B', 0.1, 0.20),
    ]);

    expect(lines, ['A', 'B']);
  });

  test('drops empty text', () {
    expect(groupIntoLines([_block('  ', 0.1, 0.1)]), isEmpty);
  });
}
