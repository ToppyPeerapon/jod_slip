import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/app_localizations.dart';
import '../../transactions/presentation/transaction_form_screen.dart';
import '../../transactions/providers.dart';
import '../application/slip_import_controller.dart';
import 'slip_review_screen.dart';

enum _ScanSource { photos, camera, manual }

/// Bottom sheet offering: pick slips from Photos, take a photo, add manually.
Future<void> showScanSlipSheet(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final source = await showModalBottomSheet<_ScanSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.pickFromPhotos),
            subtitle: Text(l10n.pickFromPhotosHint),
            onTap: () => Navigator.pop(context, _ScanSource.photos),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.takePhoto),
            onTap: () => Navigator.pop(context, _ScanSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: Text(l10n.addManually),
            onTap: () => Navigator.pop(context, _ScanSource.manual),
          ),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return;

  switch (source) {
    case _ScanSource.manual:
      await _addManually(context, ref);
    case _ScanSource.photos || _ScanSource.camera:
      await _scanImages(context, ref, source);
  }
}

Future<void> _scanImages(BuildContext context, WidgetRef ref, _ScanSource source) async {
  final picker = ImagePicker();
  final List<String> paths;
  try {
    paths = source == _ScanSource.camera
        ? [if (await picker.pickImage(source: ImageSource.camera) case final file?) file.path]
        : (await picker.pickMultiImage()).map((f) => f.path).toList(growable: false);
  } catch (error) {
    debugPrint('Image picking failed: $error');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).pickImageFailed)),
      );
    }
    return;
  }
  if (paths.isEmpty || !context.mounted) return;

  // Start scanning, then show the review screen which fills in as slips are read.
  ref.read(slipImportControllerProvider.notifier).scan(paths);
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SlipReviewScreen()));
}

Future<void> _addManually(BuildContext context, WidgetRef ref) async {
  final result = await Navigator.of(context).push<TransactionFormResult>(
    MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
  );
  if (result is! TransactionSaved) return;
  try {
    await ref.read(transactionRepositoryProvider).create(result.transaction);
  } catch (error) {
    debugPrint('Saving manual transaction failed: $error');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).errorGeneric)),
      );
    }
  }
  ref.invalidate(monthTransactionsProvider);
}
