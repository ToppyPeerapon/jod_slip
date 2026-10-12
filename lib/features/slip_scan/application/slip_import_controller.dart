import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../settings/providers.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/providers.dart';
import '../data/slip_image_store.dart';
import '../data/slip_recognizer.dart';
import '../domain/slip_draft.dart';
import '../domain/slip_parser.dart';

final slipRecognizerProvider = Provider<SlipRecognizer>((ref) => const NativeSlipRecognizer());

final slipImageStoreProvider = Provider<SlipImageStore>(
  (ref) => SlipImageStore(ref.watch(slipDirectoryProvider)),
);

final slipImportControllerProvider =
    NotifierProvider<SlipImportController, SlipImportState>(SlipImportController.new);

@immutable
class SlipImportState {
  const SlipImportState({this.drafts = const [], this.scanned = 0, this.total = 0, this.isSaving = false});

  final List<SlipDraft> drafts;
  final int scanned;
  final int total;
  final bool isSaving;

  bool get isScanning => scanned < total;

  int get saveableCount => drafts.where((d) => d.canSave).length;

  SlipImportState copyWith({List<SlipDraft>? drafts, int? scanned, int? total, bool? isSaving}) {
    return SlipImportState(
      drafts: drafts ?? this.drafts,
      scanned: scanned ?? this.scanned,
      total: total ?? this.total,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Drives the scan → review → save flow for one batch of slip images.
class SlipImportController extends Notifier<SlipImportState> {
  @override
  SlipImportState build() => const SlipImportState();

  /// Recognises each image in turn so drafts appear as they are read.
  Future<void> scan(List<String> imagePaths) async {
    state = SlipImportState(total: imagePaths.length);
    final recognizer = ref.read(slipRecognizerProvider);
    final repository = ref.read(transactionRepositoryProvider);
    final ownerNames = ref.read(ownerNamesProvider);
    final seenReferences = <String>{};

    for (final path in imagePaths) {
      final draft = await _scanOne(path, recognizer, repository, ownerNames, seenReferences);
      final reference = draft.transaction.reference;
      if (reference != null) seenReferences.add(reference);
      if (!ref.mounted) return;
      state = state.copyWith(drafts: [...state.drafts, draft], scanned: state.scanned + 1);
    }
  }

  Future<SlipDraft> _scanOne(
    String path,
    SlipRecognizer recognizer,
    TransactionRepository repository,
    List<String> ownerNames,
    Set<String> seenReferences,
  ) async {
    final now = DateTime.now();
    try {
      final recognized = await recognizer.recognize(path);
      final slip = SlipParser.parse(lines: recognized.lines, qrCodes: recognized.qrCodes);
      final reference = slip.reference;
      final isDuplicate = reference != null &&
          (seenReferences.contains(reference) || await repository.existsByReference(reference));
      return SlipDraft.fromSlip(
        imagePath: path,
        slip: slip,
        ownerNames: ownerNames,
        isDuplicate: isDuplicate,
        now: now,
      );
    } catch (error, stack) {
      debugPrint('Slip recognition failed for $path: $error\n$stack');
      return SlipDraft.failed(imagePath: path, error: error.toString(), now: now);
    }
  }

  void updateDraft(int index, SlipDraft draft) {
    state = state.copyWith(drafts: [
      for (final (i, d) in state.drafts.indexed) i == index ? draft : d,
    ]);
  }

  void removeDraft(int index) {
    state = state.copyWith(drafts: [
      for (final (i, d) in state.drafts.indexed)
        if (i != index) d,
    ]);
  }

  /// Saves every ready draft and returns how many were saved. Drafts that
  /// fail to save (e.g. a duplicate created meanwhile) stay in the list.
  Future<int> saveAll() async {
    state = state.copyWith(isSaving: true);
    final repository = ref.read(transactionRepositoryProvider);
    final imageStore = ref.read(slipImageStoreProvider);
    final remaining = <SlipDraft>[];
    var saved = 0;

    for (final draft in state.drafts) {
      if (!draft.canSave) {
        remaining.add(draft);
        continue;
      }
      String? fileName;
      try {
        fileName = await imageStore.save(draft.imagePath);
        await repository.create(draft.transaction.copyWith(slipImage: () => fileName));
        saved++;
      } on DuplicateSlipException {
        if (fileName != null) await imageStore.delete(fileName);
        remaining.add(SlipDraft(
          imagePath: draft.imagePath,
          transaction: draft.transaction,
          status: DraftStatus.duplicate,
        ));
      } catch (error, stack) {
        debugPrint('Saving slip failed: $error\n$stack');
        if (fileName != null) await imageStore.delete(fileName);
        remaining.add(draft);
      }
    }

    if (!ref.mounted) return saved;
    state = state.copyWith(drafts: remaining, isSaving: false);
    ref.invalidate(monthTransactionsProvider);
    return saved;
  }
}
