import 'money_transaction.dart';

/// Income / expense totals for a list of transactions, in satang.
class MonthSummary {
  const MonthSummary({required this.incomeSatang, required this.expenseSatang});

  factory MonthSummary.of(Iterable<MoneyTransaction> transactions) {
    var income = 0;
    var expense = 0;
    for (final tx in transactions) {
      switch (tx.type) {
        case TransactionType.income:
          income += tx.amountSatang;
        case TransactionType.expense:
          expense += tx.amountSatang;
      }
    }
    return MonthSummary(incomeSatang: income, expenseSatang: expense);
  }

  final int incomeSatang;
  final int expenseSatang;

  int get balanceSatang => incomeSatang - expenseSatang;
}
