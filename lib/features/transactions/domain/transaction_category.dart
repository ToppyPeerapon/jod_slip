import 'money_transaction.dart';

/// Built-in categories. [key] is what is stored in the database, so never
/// rename an existing key.
enum TransactionCategory {
  food('food', TransactionType.expense),
  transport('transport', TransactionType.expense),
  shopping('shopping', TransactionType.expense),
  bills('bills', TransactionType.expense),
  housing('housing', TransactionType.expense),
  health('health', TransactionType.expense),
  entertainment('entertainment', TransactionType.expense),
  education('education', TransactionType.expense),
  transferOut('transfer_out', TransactionType.expense),
  otherExpense('other_expense', TransactionType.expense),
  salary('salary', TransactionType.income),
  transferIn('transfer_in', TransactionType.income),
  sales('sales', TransactionType.income),
  investment('investment', TransactionType.income),
  otherIncome('other_income', TransactionType.income);

  const TransactionCategory(this.key, this.type);

  final String key;
  final TransactionType type;

  static List<TransactionCategory> forType(TransactionType type) =>
      values.where((c) => c.type == type).toList(growable: false);

  /// Default category for a newly scanned slip of the given [type].
  static TransactionCategory defaultFor(TransactionType type) =>
      type == TransactionType.income ? transferIn : transferOut;

  static TransactionCategory fromKey(String key, TransactionType type) {
    for (final category in values) {
      if (category.key == key) return category;
    }
    return type == TransactionType.income ? otherIncome : otherExpense;
  }
}
