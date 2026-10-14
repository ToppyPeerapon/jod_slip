import 'package:flutter_test/flutter_test.dart';
import 'package:jod_slip/core/institution/institution.dart';
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
      expect(slip.senderInstitution, Institution.kbank);
    });

    test('detects PromptPay as the receiving institution', () {
      expect(slip.receiverInstitution, Institution.promptPay);
    });
  });

  group('SlipParser – K PLUS PromptPay (logo text on the name row)', () {
    // Real Vision output shape from a K PLUS slip; names anonymised.
    const lines = [
      'โอนเงินสำเร็จ',
      'K+',
      '12 ต.ค. 69 10:39 น.',
      'นาย สมชาย ก',
      'ธ.กสิกรไทย',
      'xxx-x-x1234-X',
      'PrompiPay  น.ส.สมหญิง ใจดีมาก',
      'รหัสพร้อมเพย์',
      'x-XXXX-XXxx7-91-5',
      'จำนวน:',
      '2,900.00 บาท',
      'ค่าธรรมเนียม:',
      '0.00 บาท',
      'เลขที่รายการ:',
      'สแกน',
      '016285103958CPP13217  ตรวจสอบสลิป',
    ];

    final slip = SlipParser.parse(
      lines: lines,
      qrCodes: const ['0041000600000101030040220016285103958CPP132175102TH910401AD'],
    );

    test('finds a titled name after logo text on the same row', () {
      expect(slip.senderName, 'นาย สมชาย ก');
      expect(slip.receiverName, 'น.ส.สมหญิง ใจดีมาก');
    });

    test('reads amount, date, bank and QR reference', () {
      expect(slip.amountSatang, 290000);
      expect(slip.dateTime, DateTime(2026, 10, 12, 10, 39));
      expect(slip.senderInstitution, Institution.kbank);
      expect(slip.reference, '016285103958CPP13217');
    });

    test('receiver is paid via PromptPay', () {
      expect(slip.receiverInstitution, Institution.promptPay);
    });
  });

  group('SlipParser – Thai Credit app, English, between own accounts', () {
    const lines = [
      'Transaction Successful',
      'Reference Number : OB1791776338351aca8c',
      '12 Oct 2026 10:39',
      'นาย สมชาย ทดสอบ',
      'THAI CREDIT BANK',
      'xxx-x-55034-x',
      'นาย สมชาย ทดสอบ',
      'KASIKORNBANK',
      'xxx-x-03206-x',
      'Amount :  3,000.00',
      'Fee :  0.00',
      'Memo',
      'Scan to verify transaction',
    ];

    final slip = SlipParser.parse(lines: lines);

    test('keeps the receiver even when it has the same name as the sender', () {
      expect(slip.senderName, 'นาย สมชาย ทดสอบ');
      expect(slip.receiverName, 'นาย สมชาย ทดสอบ');
    });

    test('reads the institution of each side from its own block', () {
      expect(slip.senderInstitution, Institution.thaiCredit);
      expect(slip.receiverInstitution, Institution.kbank);
    });

    test('reads amount, date and reference', () {
      expect(slip.amountSatang, 300000);
      expect(slip.dateTime, DateTime(2026, 10, 12, 10, 39));
      expect(slip.reference, 'OB1791776338351aca8c');
    });
  });

  group('SlipParser – เป๋าตัง G-Wallet merchant payment (untitled names)', () {
    const lines = [
      'ไทยช่วยไทย พลัส 60/40',
      'เป๋าตัง',
      'ทำรายการสำเร็จ',
      'รหัสอ้างอิง 86e06ef2-9d7b-413e-9cc4-7f9ed36ae77f',
      '11 ต.ค. 2569 14:27 น.',
      'สมชาย ท***',
      'G-Wallet ID: **** ******* 6431',
      'แซ่บเด้อ',
      'อาหาร ของหวาน เครื่องดื่ม',
      'ค่าสินค้า/บริการ  192.06 บาท',
      'สิทธิไทยช่วยไทยพลัส  -44 บาท',
      'จำนวนเงินที่ชำระ  148.06 บาท',
    ];

    final slip = SlipParser.parse(lines: lines);

    test('finds untitled sender and merchant between the date and the amounts', () {
      expect(slip.senderName, 'สมชาย ท***');
      expect(slip.receiverName, 'แซ่บเด้อ');
    });

    test('uses the amount actually paid, not the price before discount', () {
      expect(slip.amountSatang, 14806);
    });

    test('keeps a dashed UUID reference whole', () {
      expect(slip.reference, '86e06ef2-9d7b-413e-9cc4-7f9ed36ae77f');
    });

    test('detects the เป๋าตัง wallet as the sender institution', () {
      expect(slip.senderInstitution, Institution.paotang);
      expect(slip.receiverInstitution, isNull);
    });

    test('reads the date', () {
      expect(slip.dateTime, DateTime(2026, 10, 11, 14, 27));
    });

    test('ignores logo text in the real Vision output', () {
      // Actual grouped Vision lines: the "ถุงเงิน" logo is read as "ถุง  เDU".
      final real = SlipParser.parse(lines: const [
        'พลัส',
        'โซดะช่วยไหย',
        '60/40  เป๋าตัง',
        'ทำรายการสำเร็จ',
        'รหัสอ้างอิง 86e06ef2-9d7b-413e-9cc4-7f9ed36ae77f',
        '11 ต.ค. 2569 14:27 น.',
        'สมชาย ท***',
        'G',
        'G-Wallet ID: **** ******* 6431',
        'แซ่บเด้อ',
        'ถุง  เDU  อาหาร ของหวาน เครื่องดื่ม',
        'ค่าสินค้า/บริการ  192.06 บาท',
        'สิทธิไทยช่วยไทยพลัส  -44 บาท',
        'จำนวนเงินที่ชำระ  148.06 บาท',
      ]);

      expect(real.senderName, 'สมชาย ท***');
      expect(real.receiverName, 'แซ่บเด้อ');
      expect(real.senderInstitution, Institution.paotang);
      expect(real.amountSatang, 14806);
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
      expect(slip.senderInstitution, Institution.scb);
    });
  });

  group('SlipParser – QR payload', () {
    test('prefers the QR transaction ref and sending bank', () {
      final slip = SlipParser.parse(
        lines: const ['ไทยพาณิชย์', 'จำนวนเงิน 20.00 บาท', 'รหัสอ้างอิง: AAAAAAAAAAAA'],
        qrCodes: const ['0041000600000101030040220014242082547BPM049885102TH9104ABCD'],
      );

      expect(slip.reference, '014242082547BPM04988');
      expect(slip.senderInstitution, Institution.kbank);
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
