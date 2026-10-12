import 'package:flutter_test/flutter_test.dart';
import 'package:jod_slip/features/transactions/domain/money_transaction.dart';
import 'package:jod_slip/features/transactions/domain/month_summary.dart';
import 'package:jod_slip/features/transactions/domain/transaction_category.dart';

MoneyTransaction _tx(TransactionType type, int satang) => MoneyTransaction(
      type: type,
      amountSatang: satang,
      category: TransactionCategory.defaultFor(type),
      occurredAt: DateTime(2026, 10, 1),
      createdAt: DateTime(2026, 10, 1),
    );

void main() {
  test('sums income and expense and computes balance', () {
    final summary = MonthSummary.of([
      _tx(TransactionType.income, 5000000),
      _tx(TransactionType.expense, 150000),
      _tx(TransactionType.expense, 8900),
    ]);

    expect(summary.incomeSatang, 5000000);
    expect(summary.expenseSatang, 158900);
    expect(summary.balanceSatang, 4841100);
  });

  test('empty list is all zero', () {
    final summary = MonthSummary.of(const []);
    expect(summary.balanceSatang, 0);
  });
}
