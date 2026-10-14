import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _languages = {'th': 'ไทย', 'en': 'English'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final names = ref.watch(ownerNamesProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            title: Text(l10n.ownerNames, style: text.titleMedium),
            subtitle: Text(l10n.ownerNamesHint),
          ),
          if (names.isEmpty)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.noOwnerNames, style: text.bodyMedium),
            ),
          for (final name in names)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(name),
              trailing: IconButton(
                tooltip: l10n.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref.read(ownerNamesProvider.notifier).remove(name),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.addName),
                onPressed: () => _addName(context, ref),
              ),
            ),
          ),
          const Divider(height: 32),
          ListTile(title: Text(l10n.language, style: text.titleMedium)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: [
                for (final MapEntry(:key, :value) in _languages.entries) ButtonSegment(value: key, label: Text(value)),
              ],
              selected: {locale.languageCode},
              onSelectionChanged: (selection) => ref.read(localeProvider.notifier).change(selection.first),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addName(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(context: context, builder: (_) => const _AddNameDialog());
    if (name != null) await ref.read(ownerNamesProvider.notifier).add(name);
  }
}

/// Owns its controller so it is disposed only after the close animation.
class _AddNameDialog extends StatefulWidget {
  const _AddNameDialog();

  @override
  State<_AddNameDialog> createState() => _AddNameDialogState();
}

class _AddNameDialogState extends State<_AddNameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.addName),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: l10n.nameFieldLabel),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _controller.text), child: Text(l10n.save)),
      ],
    );
  }
}
