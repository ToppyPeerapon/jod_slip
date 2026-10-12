import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/thai_format.dart';
import '../../../core/theme/money_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../transactions/domain/money_transaction.dart';
import '../../transactions/presentation/category_presentation.dart';
import '../../transactions/presentation/transaction_form_screen.dart';
import '../application/slip_import_controller.dart';
import '../domain/slip_draft.dart';

/// Lists scanned slips so the user can fix anything OCR got wrong before
/// saving them all at once.
class SlipReviewScreen extends ConsumerWidget {
  const SlipReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(slipImportControllerProvider);
    final controller = ref.read(slipImportControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reviewSlips),
        bottom: state.isScanning
            ? PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Column(
                  children: [
                    Text(l10n.scanningProgress(state.scanned + 1, state.total)),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: state.total == 0 ? null : state.scanned / state.total),
                  ],
                ),
              )
            : null,
      ),
      body: state.drafts.isEmpty && !state.isScanning
          ? Center(child: Text(l10n.noDrafts))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.drafts.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final draft = state.drafts[index];
                return _DraftTile(
                  draft: draft,
                  onTap: () => _edit(context, controller, index, draft),
                  onRemove: () => controller.removeDraft(index),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton.icon(
            icon: state.isSaving
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: Text(l10n.saveAll(state.saveableCount)),
            onPressed: state.isScanning || state.isSaving || state.saveableCount == 0
                ? null
                : () => _saveAll(context, ref),
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, SlipImportController controller, int index, SlipDraft draft) async {
    final result = await Navigator.of(context).push<TransactionFormResult>(
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(initial: draft.transaction, imagePath: draft.imagePath),
      ),
    );
    if (result is TransactionSaved) controller.updateDraft(index, draft.withTransaction(result.transaction));
  }

  Future<void> _saveAll(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    final saved = await ref.read(slipImportControllerProvider.notifier).saveAll();

    messenger.showSnackBar(SnackBar(content: Text(l10n.savedCount(saved))));
    if (ref.read(slipImportControllerProvider).drafts.isEmpty) navigator.pop();
  }
}

class _DraftTile extends StatelessWidget {
  const _DraftTile({required this.draft, required this.onTap, required this.onRemove});

  final SlipDraft draft;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = AppFormat(Localizations.localeOf(context).languageCode);
    final colors = Theme.of(context).colorScheme;
    final tx = draft.transaction;
    final statusMessage = switch (draft.status) {
      DraftStatus.ready => null,
      DraftStatus.needsAmount => l10n.statusNeedsAmount,
      DraftStatus.duplicate => l10n.statusDuplicate,
      DraftStatus.failed => l10n.statusFailed,
    };

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(draft.imagePath),
          width: 48,
          height: 64,
          fit: BoxFit.cover,
          cacheWidth: 144,
          errorBuilder: (_, _, _) => const SizedBox(width: 48, height: 64, child: Icon(Icons.image_not_supported)),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              tx.amountSatang > 0 ? format.baht(tx.signedSatang, signed: true) : '—',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.forType(tx.type),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            tx.type == TransactionType.income ? l10n.income : l10n.expense,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [format.dateTime(tx.occurredAt), tx.category.label(l10n), ?tx.counterparty].join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (statusMessage != null)
            Text(statusMessage, style: TextStyle(color: colors.error, fontWeight: FontWeight.w500)),
        ],
      ),
      trailing: IconButton(
        tooltip: l10n.removeFromList,
        icon: const Icon(Icons.close),
        onPressed: onRemove,
      ),
    );
  }
}
