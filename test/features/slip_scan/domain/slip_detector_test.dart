import 'package:flutter_test/flutter_test.dart';
import 'package:jod_slip/features/slip_scan/data/slip_recognizer.dart';
import 'package:jod_slip/features/slip_scan/domain/slip_detector.dart';

RecognizedSlip _quick(List<String> lines, [List<String> qr = const []]) => RecognizedSlip(lines: lines, qrCodes: qr);

void main() {
  group('looksLikeSlip', () {
    test('a slip verification QR is enough', () {
      expect(looksLikeSlip(_quick(const [], const ['0041000600000101030040220014242082547BPM049885102TH9104ABCD'])), isTrue);
    });

    test('masked account number with an amount (K PLUS, fast English OCR)', () {
      expect(looksLikeSlip(_quick(const ['K+', 'xxx-x-x3206-x', 'x-xxxx-xxxx7-91-5', '2,900.00', '0.00'])), isTrue);
    });

    test('wallet slip with masked ID and amount (เป๋าตัง)', () {
      expect(looksLikeSlip(_quick(const ['G-Wallet ID: **** ******* 6431', '192.06', '148.06'])), isTrue);
    });

    test('English slip keywords with an amount', () {
      expect(looksLikeSlip(_quick(const ['Transaction Successful', 'Amount :', '3,000.00'])), isTrue);
    });

    test('ordinary photos are not slips', () {
      expect(looksLikeSlip(_quick(const [])), isFalse);
      expect(looksLikeSlip(_quick(const ['SALE', 'NEW ARRIVALS'])), isFalse);
    });

    test('a price alone is not a slip', () {
      expect(looksLikeSlip(_quick(const ['Latte', '120.00'])), isFalse);
    });

    test('a payment QR (not a slip QR) without slip text is not a slip', () {
      expect(
        looksLikeSlip(_quick(const ['Scan to pay'], const ['00020101021129370016A000000677010111011300668123456785802TH530376463041234'])),
        isFalse,
      );
    });
  });
}
