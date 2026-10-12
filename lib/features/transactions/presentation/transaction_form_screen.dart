import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/amount_input.dart';
import '../../../core/formatting/thai_format.dart';
import '../../../core/theme/money_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../slip_scan/application/slip_import_controller.dart';
import '../domain/money_transaction.dart';
import '../domain/transaction_category.dart';
import 'category_presentation.dart';

sealed class TransactionFormResult {
  const TransactionFormResult();
}

class TransactionSaved extends TransactionFormResult {
  const TransactionSaved(this.transaction);

  final MoneyTransaction transaction;
}

class TransactionDeleted extends TransactionFormResult {
  const TransactionDeleted();
}

/// Create or edit a transaction. Pops with a [TransactionFormResult]; the
/// caller decides how to persist it (DB for saved items, draft list for scans).
class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, this.initial, this.allowDelete = false, this.imagePath});

  final MoneyTransaction? initial;
  final bool allowDelete;

  /// Local path of an image not yet stored (scan drafts). When null, the
  /// saved slip image of [initial] is shown, if any.
  final String? imagePath;

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _counterparty;
  late final TextEditingController _note;
  late TransactionType _type;
  late TransactionCategory _category;
  late DateTime _occurredAt;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _type = initial?.type ?? TransactionType.expense;
    _category = initial?.category ?? TransactionCategory.forType(_type).first;
    _occurredAt = initial?.occurredAt ?? DateTime.now();
    _amount = TextEditingController(text: satangToInput(initial?.amountSatang ?? 0));
    _counterparty = TextEditingController(text: initial?.counterparty ?? '');
    _note = TextEditingController(text: initial?.note ?? '');
  }

  @override
  void dispose() {
    _amount.dispose();
    _counterparty.dispose();
    _note.dispose();
    super.dispose();
  }

  void _changeType(TransactionType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _category = TransactionCategory.defaultFor(type);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (picked == null) return;
    setState(() {
      _occurredAt = DateTime(picked.year, picked.month, picked.day, _occurredAt.hour, _occurredAt.minute);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_occurredAt));
    if (picked == null) return;
    setState(() {
      _occurredAt = DateTime(_occurredAt.year, _occurredAt.month, _occurredAt.day, picked.hour, picked.minute);
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final counterparty = _counterparty.text.trim();
    final base = widget.initial ??
        MoneyTransaction(
          type: _type,
          amountSatang: 0,
          category: _category,
          occurredAt: _occurredAt,
          createdAt: DateTime.now(),
        );
    final result = base.copyWith(
      type: _type,
      amountSatang: parseBahtToSatang(_amount.text),
      category: _category,
      occurredAt: _occurredAt,
      note: _note.text.trim(),
      counterparty: () => counterparty.isEmpty ? null : counterparty,
    );
    Navigator.of(context).pop(TransactionSaved(result));
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if ((confirmed ?? false) && mounted) Navigator.of(context).pop(const TransactionDeleted());
  }

  File? _imageFile() {
    if (widget.imagePath case final path?) return File(path);
    if (widget.initial?.slipImage case final name?) return ref.read(slipImageStoreProvider).resolve(name);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = AppFormat(Localizations.localeOf(context).languageCode);
    final colors = Theme.of(context).colorScheme;
    final image = _imageFile();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial?.id == null ? l10n.newTransaction : l10n.editTransaction),
        actions: [
          if (widget.allowDelete)
            IconButton(tooltip: l10n.delete, icon: const Icon(Icons.delete_outline), onPressed: _confirmDelete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<TransactionType>(
              segments: [
                ButtonSegment(value: TransactionType.expense, label: Text(l10n.expense), icon: const Icon(Icons.north_east)),
                ButtonSegment(value: TransactionType.income, label: Text(l10n.income), icon: const Icon(Icons.south_west)),
              ],
              selected: {_type},
              onSelectionChanged: (selection) => _changeType(selection.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              autofocus: widget.initial == null || widget.initial!.amountSatang <= 0,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AmountInputFormatter()],
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: colors.forType(_type)),
              decoration: InputDecoration(labelText: l10n.amount, prefixText: '฿ ', border: const OutlineInputBorder()),
              validator: (value) {
                final satang = parseBahtToSatang(value ?? '');
                return satang == null || satang <= 0 ? l10n.amountRequired : null;
              },
            ),
            const SizedBox(height: 16),
            Text(l10n.category, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in TransactionCategory.forType(_type))
                  ChoiceChip(
                    avatar: Icon(category.icon, size: 18),
                    label: Text(category.label(l10n)),
                    selected: category == _category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text('${_occurredAt.day}/${_occurredAt.month}/${format.displayYear(_occurredAt)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(format.time(_occurredAt)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _counterparty,
              decoration: InputDecoration(
                labelText: _type == TransactionType.expense ? l10n.paidTo : l10n.receivedFrom,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.note, border: const OutlineInputBorder()),
            ),
            if (image != null) ...[
              const SizedBox(height: 16),
              Text(l10n.slipImage, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  image,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox(height: 48, child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton(onPressed: _save, child: Text(l10n.save)),
        ),
      ),
    );
  }
}
