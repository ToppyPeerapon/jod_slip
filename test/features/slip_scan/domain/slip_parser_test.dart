import 'package:flutter_test/flutter_test.dart';
import 'package:jod_slip/core/bank/thai_bank.dart';
import 'package:jod_slip/features/slip_scan/domain/slip_parser.dart';

void main() {
  group('SlipParser – K PLUS style (unlabelled parties)', () {
    const lines = [
      'โอนเงินสำเร็จ',
      '12 ต.ค. 69 14:30 น.',
      'นาย พีรพล ช.',
      'ธ.กสิกรไทย',
      'xxx-x-x1234-x',
      'น.ส. สมหญิง ใจดี',
      'พร้อมเพย์',
      'xxx-xxx-5678',
      'เลขที่รายการ:',
      '015285143022BTF06123',
      'จำนวน:  1,500.00 บาท',
      'ค่าธรรมเนียม:  0.00 บาท',
    ];

    final slip = SlipParser.parse(lines: lines);

    test('reads the amount from the labelled line, not the fee', () {
      expect(slip.amountSatang, 150000);
    });

    test('reads the Buddhist-year date and time', () {
      expect(slip.dateTime, DateTime(2026, 10, 12, 14, 30));
    });

    test('treats the first titled name as sender and second as receiver', () {
      expect(slip.senderName, 'นาย พีรพล ช.');
      expect(slip.receiverName, 'น.ส. สมหญิง ใจดี');
    });

    test('reads the reference from the line after its label', () {
      expect(slip.reference, '015285143022BTF06123');
    });

    test('detects the bank from text', () {
      expect(slip.bank, ThaiBank.kbank);
    });
  });

  group('SlipParser – SCB style (labelled parties)', () {
    const lines = [
      'SCB EASY',
      'โอนเงินสำเร็จ',
      '12 ต.ค. 2569 - 09:05',
      'รหัสอ้างอิง: 202610121234567890',
      'จาก',
      'นาย พีรพล ชื่นใจ',
      'xxx-xxx123-4',
      'ไปยัง',
      'ร้านกาแฟดี',
      'จำนวนเงิน',
      '89.00',
    ];

    final slip = SlipParser.parse(lines: lines);

    test('reads the amount on the line after the label', () {
      expect(slip.amountSatang, 8900);
    });

    test('reads labelled sender and receiver', () {
      expect(slip.senderName, 'นาย พีรพล ชื่นใจ');
      expect(slip.receiverName, 'ร้านกาแฟดี');
    });

    test('reads the reference on the label line', () {
      expect(slip.reference, '202610121234567890');
    });

    test('reads the date and time', () {
      expect(slip.dateTime, DateTime(2026, 10, 12, 9, 5));
    });

    test('detects SCB', () {
      expect(slip.bank, ThaiBank.scb);
    });
  });

  group('SlipParser – QR payload', () {
    test('prefers the QR transaction ref and sending bank', () {
      final slip = SlipParser.parse(
        lines: const ['ไทยพาณิชย์', 'จำนวนเงิน 20.00 บาท', 'รหัสอ้างอิง: AAAAAAAAAAAA'],
        qrCodes: const ['0041000600000101030040220014242082547BPM049885102TH9104ABCD'],
      );

      expect(slip.reference, '014242082547BPM04988');
      expect(slip.bank, ThaiBank.kbank);
    });

    test('ignores QR codes that are not slip payloads', () {
      final slip = SlipParser.parse(lines: const ['hello'], qrCodes: const ['https://example.com']);
      expect(slip.reference, isNull);
    });
  });

  group('SlipParser – amount fallbacks', () {
    test('uses the largest currency amount when there is no label', () {
      final slip = SlipParser.parse(lines: const ['ชำระเงินสำเร็จ', '250.50 บาท', 'ค่าธรรมเนียม 10.00 บาท']);
      expect(slip.amountSatang, 25050);
    });

    test('ignores the remaining balance line', () {
      final slip = SlipParser.parse(lines: const [
        'ยอดเงินคงเหลือ 99,999.00 บาท',
        'Amount 1,234.56 THB',
      ]);
      expect(slip.amountSatang, 123456);
    });

    test('returns null when no amount is present', () {
      final slip = SlipParser.parse(lines: const ['ไม่มีจำนวน']);
      expect(slip.amountSatang, isNull);
    });
  });

  group('SlipParser – English slip', () {
    test('parses English labels and dates', () {
      final slip = SlipParser.parse(lines: const [
        'Transfer successful',
        '12 Oct 2026 18:45:10',
        'From  MR. PEERAPON C',
        'To  MS. SOMYING J',
        'Amount  3,000.00 THB',
        'Ref No. 2026101299887766',
      ]);

      expect(slip.amountSatang, 300000);
      expect(slip.dateTime, DateTime(2026, 10, 12, 18, 45, 10));
      expect(slip.senderName, 'MR. PEERAPON C');
      expect(slip.receiverName, 'MS. SOMYING J');
      expect(slip.reference, '2026101299887766');
    });
  });
}
