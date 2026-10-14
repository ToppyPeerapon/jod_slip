import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../settings/providers.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/providers.dart';
import '../data/photo_library_source.dart';
import '../data/slip_image_store.dart';
import '../data/slip_recognizer.dart';
import '../domain/slip_data.dart';
import '../domain/slip_detector.dart';
import '../domain/slip_draft.dart';
import '../domain/slip_parser.dart';

final slipRecognizerProvider = Provider<SlipRecognizer>((ref) => const NativeSlipRecognizer());

final photoLibrarySourceProvider = Provider<PhotoLibrarySource>((ref) => const NativePhotoLibrarySource());

final slipImageStoreProvider = Provider<SlipImageStore>((ref) => SlipImageStore(ref.watch(slipDirectoryProvider)));

final slipImportControllerProvider = NotifierProvider<SlipImportController, SlipImportState>(SlipImportController.new);

/// [picked]: images the user chose. [library]: searching the whole photo
/// library, where [SlipImportState.scanned]/[SlipImportState.total] count photos.
enum ScanMode { picked, library }

enum LibraryScanOutcome { completed, cancelled, noAccess }

@immutable
class SlipImportState {
  const SlipImportState({
    this.drafts = const [],
    this.scanned = 0,
    this.total = 0,
    this.isSaving = false,
    this.mode = ScanMode.picked,
    this.skippedDuplicates = 0,
  });

  final List<SlipDraft> drafts;
  final int scanned;
  final int total;
  final bool isSaving;
  final ScanMode mode;

  /// Library mode: slips found that were already saved, so not listed.
  final int skippedDuplicates;

  bool get isScanning => scanned < total;

  int get saveableCount => drafts.where((d) => d.canSave).length;

  SlipImportState copyWith({
    List<SlipDraft>? drafts,
    int? scanned,
    int? total,
    bool? isSaving,
    int? skippedDuplicates,
  }) {
    return SlipImportState(
      drafts: drafts ?? this.drafts,
      scanned: scanned ?? this.scanned,
      total: total ?? this.total,
      isSaving: isSaving ?? this.isSaving,
      mode: mode,
      skippedDuplicates: skippedDuplicates ?? this.skippedDuplicates,
    );
  }
}

/// Drives the scan → review → save flow for one batch of slip images.
class SlipImportController extends Notifier<SlipImportState> {
  var _cancelRequested = false;

  @override
  SlipImportState build() => const SlipImportState();

  /// Stops a running library search after the current photo.
  void cancelScan() => _cancelRequested = true;

  /// Searches the photo library (newest first, optionally only photos since
  /// [since]) and turns every photo that looks like a new slip into a draft.
  ///
  /// Each photo gets a cheap quick scan; only likely slips get full Thai OCR.
  /// Slips already saved are counted in [SlipImportState.skippedDuplicates]
  /// instead of listed. A completed search records its start time so the
  /// next search can cover only newer photos.
  Future<LibraryScanOutcome> scanLibrary({DateTime? since}) async {
    final library = ref.read(photoLibrarySourceProvider);
    final access = await library.requestAccess();
    if (access != PhotoAccess.authorized && access != PhotoAccess.limited) return LibraryScanOutcome.noAccess;

    final startedAt = DateTime.now();
    final assets = await library.listImages(since: since);
    _cancelRequested = false;
    state = SlipImportState(mode: ScanMode.library, total: assets.length);

    final recognizer = ref.read(slipRecognizerProvider);
    final repository = ref.read(transactionRepositoryProvider);
    final ownerNames = ref.read(ownerNamesProvider);
    final seenReferences = <String>{};

    for (final asset in assets) {
      if (_cancelRequested || !ref.mounted) return LibraryScanOutcome.cancelled;
      final draft = await _scanLibraryAsset(asset, library, recognizer, repository, ownerNames, seenReferences);
      if (!ref.mounted) return LibraryScanOutcome.cancelled;

      final isDuplicate = draft?.status == DraftStatus.duplicate;
      if (draft?.transaction.reference case final reference?) seenReferences.add(reference);
      state = state.copyWith(
        scanned: state.scanned + 1,
        drafts: draft == null || isDuplicate ? null : [...state.drafts, draft],
        skippedDuplicates: isDuplicate ? state.skippedDuplicates + 1 : null,
      );
    }

    await ref.read(settingsRepositoryProvider).saveLastLibraryScan(startedAt);
    return LibraryScanOutcome.completed;
  }

  /// A draft for the photo if it is a slip, otherwise null.
  Future<SlipDraft?> _scanLibraryAsset(
    PhotoAsset asset,
    PhotoLibrarySource library,
    SlipRecognizer recognizer,
    TransactionRepository repository,
    List<String> ownerNames,
    Set<String> seenReferences,
  ) async {
    try {
      if (!looksLikeSlip(await library.quickScan(asset.id))) return null;
      final path = await library.export(asset.id);
      final draft = await _scanOne(path, recognizer, repository, ownerNames, seenReferences);
      // A photo that passed the quick check but fails full OCR is noise here.
      return draft.status == DraftStatus.failed ? null : draft;
    } catch (error) {
      // e.g. an iCloud-only photo that is not on the device: skip it.
      debugPrint('Skipping photo ${asset.id}: $error');
      return null;
    }
  }

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
      final isDuplicate = await _isDuplicate(slip, repository, seenReferences);
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

  /// Same reference as a saved or already-scanned slip, or — when the
  /// reference could not be read — same amount and time as a saved one.
  Future<bool> _isDuplicate(SlipData slip, TransactionRepository repository, Set<String> seenReferences) async {
    final reference = slip.reference;
    if (reference != null && (seenReferences.contains(reference) || await repository.existsByReference(reference))) {
      return true;
    }
    final amount = slip.amountSatang;
    final time = slip.dateTime;
    return amount != null && time != null && await repository.existsMatching(amountSatang: amount, occurredAt: time);
  }

  void updateDraft(int index, SlipDraft draft) {
    state = state.copyWith(drafts: [for (final (i, d) in state.drafts.indexed) i == index ? draft : d]);
  }

  void removeDraft(int index) {
    state = state.copyWith(
      drafts: [
        for (final (i, d) in state.drafts.indexed)
          if (i != index) d,
      ],
    );
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
        remaining.add(
          SlipDraft(imagePath: draft.imagePath, transaction: draft.transaction, status: DraftStatus.duplicate),
        );
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
