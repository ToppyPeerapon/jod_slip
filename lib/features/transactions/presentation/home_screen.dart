import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/thai_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../slip_scan/application/slip_import_controller.dart';
import '../../slip_scan/presentation/scan_slip_sheet.dart';
import '../domain/money_transaction.dart';
import '../domain/month_summary.dart';
import '../providers.dart';
import 'transaction_form_screen.dart';
import 'widgets/month_summary_card.dart';
import 'widgets/transaction_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final format = AppFormat(Localizations.localeOf(context).languageCode);
    final month = ref.watch(selectedMonthProvider);
    final transactions = ref.watch(monthTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showScanSlipSheet(context, ref),
        icon: const Icon(Icons.document_scanner_outlined),
        label: Text(l10n.scanSlip),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(monthTransactionsProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _MonthSwitcher(month: month, format: format)),
            ...switch (transactions) {
              // Matching on `value` keeps the previous list visible while refreshing.
              AsyncValue(:final value?) => _content(context, ref, value, format),
              AsyncValue(:final error?) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('${l10n.errorGeneric}\n$error', textAlign: TextAlign.center)),
                  ),
                ],
              _ => [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))],
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, WidgetRef ref, List<MoneyTransaction> items, AppFormat format) {
    final summary = SliverToBoxAdapter(
      child: MonthSummaryCard(summary: MonthSummary.of(items), format: format),
    );
    if (items.isEmpty) {
      return [summary, const SliverFillRemaining(hasScrollBody: false, child: _EmptyState())];
    }

    final byDay = groupBy(items, (MoneyTransaction t) => DateUtils.dateOnly(t.occurredAt));
    return [
      summary,
      const SliverToBoxAdapter(child: SizedBox(height: 8)),
      for (final MapEntry(key: day, value: dayItems) in byDay.entries)
        SliverList.list(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(format.dayHeader(day), style: Theme.of(context).textTheme.labelLarge),
          ),
          for (final tx in dayItems)
            TransactionTile(transaction: tx, format: format, onTap: () => _edit(context, ref, tx)),
        ]),
      const SliverToBoxAdapter(child: SizedBox(height: 96)),
    ];
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, MoneyTransaction tx) async {
    final result = await Navigator.of(context).push<TransactionFormResult>(
      MaterialPageRoute(builder: (_) => TransactionFormScreen(initial: tx, allowDelete: true)),
    );
    if (result == null) return;

    final repository = ref.read(transactionRepositoryProvider);
    try {
      switch (result) {
        case TransactionSaved(:final transaction):
          await repository.update(transaction);
        case TransactionDeleted():
          await repository.delete(tx.id!);
          if (tx.slipImage case final image?) await ref.read(slipImageStoreProvider).delete(image);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorGeneric)),
        );
      }
    }
    ref.invalidate(monthTransactionsProvider);
  }
}

class _MonthSwitcher extends ConsumerWidget {
  const _MonthSwitcher({required this.month, required this.format});

  final DateTime month;
  final AppFormat format;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(selectedMonthProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.previousMonth,
            icon: const Icon(Icons.chevron_left),
            onPressed: notifier.previous,
          ),
          Expanded(
            child: Text(
              format.monthYear(month),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: l10n.nextMonth,
            icon: const Icon(Icons.chevron_right),
            onPressed: notifier.next,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(l10n.noTransactions, style: text.titleMedium),
          const SizedBox(height: 8),
          Text(l10n.noTransactionsHint, style: text.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
