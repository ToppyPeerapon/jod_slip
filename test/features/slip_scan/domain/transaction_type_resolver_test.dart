import 'package:flutter_test/flutter_test.dart';
import 'package:jod_slip/features/slip_scan/domain/slip_data.dart';
import 'package:jod_slip/features/slip_scan/domain/transaction_type_resolver.dart';
import 'package:jod_slip/features/transactions/domain/money_transaction.dart';

void main() {
  const owners = ['พีรพล ชื่นใจ', 'Peerapon Chuenjai'];

  test('expense when the owner is the sender', () {
    const slip = SlipData(senderName: 'นาย พีรพล ช***', receiverName: 'น.ส. สมหญิง ใจดี');
    expect(resolveTransactionType(slip, owners), TransactionType.expense);
  });

  test('income when the owner is the receiver', () {
    const slip = SlipData(senderName: 'น.ส. สมหญิง ใจดี', receiverName: 'MR. PEERAPON C');
    expect(resolveTransactionType(slip, owners), TransactionType.income);
  });

  group('transfer between accounts with the same name', () {
    test('is income even when the owner is the sender', () {
      const slip = SlipData(senderName: 'นาย พีรพล ชื่นใจ', receiverName: 'นาย พีรพล ชื่นใจ');
      expect(resolveTransactionType(slip, owners), TransactionType.income);
    });

    test('is income without any owner names configured', () {
      const slip = SlipData(senderName: 'นาย สมชาย ทดสอบ', receiverName: 'นาย สมชาย ทดสอบ');
      expect(resolveTransactionType(slip, const []), TransactionType.income);
    });

    test('ignores differences in titles, spacing and masking', () {
      const slip = SlipData(senderName: 'นาย สมชาย ท***', receiverName: 'สมชาย  ท***');
      expect(resolveTransactionType(slip, const []), TransactionType.income);
    });

    test('different people with the same first name are not the same account', () {
      const slip = SlipData(senderName: 'นาย สมชาย ทดสอบ', receiverName: 'นาย สมชาย ใจดี');
      expect(resolveTransactionType(slip, const []), TransactionType.expense);
    });
  });

  test('defaults to expense when nobody matches', () {
    const slip = SlipData(senderName: 'นาย ก', receiverName: 'นาย ข');
    expect(resolveTransactionType(slip, owners), TransactionType.expense);
  });

  test('defaults to expense when no owner names are configured', () {
    const slip = SlipData(receiverName: 'นาย พีรพล ชื่นใจ');
    expect(resolveTransactionType(slip, const []), TransactionType.expense);
  });

  test('ignores tokens shorter than three characters', () {
    const slip = SlipData(receiverName: 'นาย ก');
    expect(resolveTransactionType(slip, const ['ก ข']), TransactionType.expense);
  });
}
