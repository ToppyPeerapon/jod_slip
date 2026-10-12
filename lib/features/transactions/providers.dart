import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/transaction_repository.dart';
import 'domain/money_transaction.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => SqliteTransactionRepository(ref.watch(databaseProvider)),
);

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(SelectedMonthNotifier.new);

/// The month shown on the home screen (always the 1st of the month).
class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void previous() => state = DateTime(state.year, state.month - 1);

  void next() => state = DateTime(state.year, state.month + 1);

  void select(DateTime date) => state = DateTime(date.year, date.month);
}

final monthTransactionsProvider = FutureProvider<List<MoneyTransaction>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.findByMonth(ref.watch(selectedMonthProvider));
});
