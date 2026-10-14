import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/thai_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/providers.dart';
import '../application/slip_import_controller.dart';
import '../data/photo_library_source.dart';
import 'slip_review_screen.dart';

/// Search the whole photo library for slips: ask for access, pick a date
/// range, then show the review screen while the search runs.
Future<void> startLibraryScan(BuildContext context, WidgetRef ref) async {
  final library = ref.read(photoLibrarySourceProvider);
  final access = await library.requestAccess();
  if (!context.mounted) return;

  if (access != PhotoAccess.authorized && access != PhotoAccess.limited) {
    await _showNoAccessDialog(context, library);
    return;
  }

  final range = await _pickRange(context, ref.read(settingsRepositoryProvider).lastLibraryScan());
  if (range == null || !context.mounted) return;

  if (access == PhotoAccess.limited) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).photoAccessLimited)));
  }

  final controller = ref.read(slipImportControllerProvider.notifier);
  controller.scanLibrary(since: range.since);
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SlipReviewScreen()));
}

/// The chosen range; [since] is null for "all photos".
typedef _Range = ({DateTime? since});

Future<_Range?> _pickRange(BuildContext context, DateTime? lastScan) {
  final l10n = AppLocalizations.of(context);
  final format = AppFormat(Localizations.localeOf(context).languageCode);
  final now = DateTime.now();

  Widget option(BuildContext context, IconData icon, String label, DateTime? since) => SimpleDialogOption(
    onPressed: () => Navigator.pop<_Range>(context, (since: since)),
    child: Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
      ],
    ),
  );

  return showDialog<_Range>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.libraryRangeTitle),
      children: [
        if (lastScan != null) option(context, Icons.update, l10n.rangeSinceLast(format.dateTime(lastScan)), lastScan),
        option(context, Icons.calendar_view_month, l10n.rangeLastMonth, DateTime(now.year, now.month - 1, now.day)),
        option(context, Icons.date_range, l10n.rangeLast3Months, DateTime(now.year, now.month - 3, now.day)),
        option(context, Icons.photo_library_outlined, l10n.rangeAll, null),
      ],
    ),
  );
}

Future<void> _showNoAccessDialog(BuildContext context, PhotoLibrarySource library) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.photoAccessTitle),
      content: Text(l10n.photoAccessBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            library.openSettings();
          },
          child: Text(l10n.openSettings),
        ),
      ],
    ),
  );
}
