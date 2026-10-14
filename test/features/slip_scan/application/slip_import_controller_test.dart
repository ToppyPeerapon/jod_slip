import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jod_slip/core/database/app_database.dart';
import 'package:jod_slip/core/institution/institution.dart';
import 'package:jod_slip/core/providers.dart';
import 'package:jod_slip/features/slip_scan/application/slip_import_controller.dart';
import 'package:jod_slip/features/slip_scan/data/photo_library_source.dart';
import 'package:jod_slip/features/slip_scan/data/slip_recognizer.dart';
import 'package:jod_slip/features/slip_scan/domain/slip_draft.dart';
import 'package:jod_slip/features/transactions/domain/money_transaction.dart';
import 'package:jod_slip/features/transactions/domain/transaction_category.dart';
import 'package:jod_slip/features/settings/providers.dart';
import 'package:jod_slip/features/transactions/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeRecognizer implements SlipRecognizer {
  _FakeRecognizer(this._results);

  final Map<String, RecognizedSlip> _results;

  @override
  Future<RecognizedSlip> recognize(String imagePath) async =>
      _results[imagePath] ?? (throw Exception('unreadable image'));
}

const _outgoing = RecognizedSlip(
  lines: ['12 ต.ค. 69 14:30 น.', 'นาย พีรพล ช.', 'ธ.กสิกรไทย', 'น.ส. สมหญิง ใจดี', 'รหัสพร้อมเพย์', 'จำนวน: 1,500.00 บาท', 'เลขที่รายการ: REFOUT1234567'],
  qrCodes: [],
);

const _incoming = RecognizedSlip(
  lines: ['13 ต.ค. 69 09:00 น.', 'นาย สมชาย รักดี', 'ธ.ไทยพาณิชย์', 'นาย พีรพล ชื่นใจ', 'ธ.กสิกรไทย', 'จำนวน: 200.00 บาท', 'เลขที่รายการ: REFIN12345678'],
  qrCodes: [],
);

class _FakeLibrary implements PhotoLibrarySource {
  _FakeLibrary({required this.access, required this.assets, required this.quick, required this.exports});

  final PhotoAccess access;
  final List<PhotoAsset> assets;
  final Map<String, RecognizedSlip> quick;
  final Map<String, String> exports;
  DateTime? requestedSince;
  void Function(String id)? onQuickScan;

  @override
  Future<PhotoAccess> requestAccess() async => access;

  @override
  Future<List<PhotoAsset>> listImages({DateTime? since}) async {
    requestedSince = since;
    return assets;
  }

  @override
  Future<RecognizedSlip> quickScan(String assetId) async {
    onQuickScan?.call(assetId);
    return quick[assetId] ?? (throw Exception('not on device'));
  }

  @override
  Future<String> export(String assetId) async => exports[assetId]!;

  @override
  Future<void> openSettings() async {}
}

const _slipLooking = RecognizedSlip(lines: ['xxx-x-x1234-x', '1,500.00'], qrCodes: []);
const _catPhoto = RecognizedSlip(lines: [], qrCodes: []);

const _noAmount = RecognizedSlip(lines: ['12 ต.ค. 69 10:00 น.'], qrCodes: []);

void main() {
  late Database db;
  late Directory slipDir;
  late ProviderContainer container;
  late _FakeLibrary library;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    slipDir = await Directory.systemTemp.createTemp('slips_test');
    SharedPreferences.setMockInitialValues({'owner_names': ['พีรพล ชื่นใจ']});
    final prefs = await SharedPreferences.getInstance();

    await File('${slipDir.path}/out.jpg').writeAsBytes([1, 2, 3]);
    await File('${slipDir.path}/in.jpg').writeAsBytes([4, 5, 6]);

    library = _FakeLibrary(
      access: PhotoAccess.authorized,
      assets: [
        for (final id in ['out', 'cat', 'in', 'icloud']) PhotoAsset(id: id, createdAt: DateTime(2026, 10, 12)),
      ],
      quick: {'out': _slipLooking, 'cat': _catPhoto, 'in': _slipLooking},
      exports: {'out': '${slipDir.path}/out.jpg', 'in': '${slipDir.path}/in.jpg'},
    );

    container = ProviderContainer(overrides: [
      photoLibrarySourceProvider.overrideWith((ref) => library),
      databaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
      slipDirectoryProvider.overrideWithValue(Directory('${slipDir.path}/store')),
      slipRecognizerProvider.overrideWithValue(_FakeRecognizer({
        '${slipDir.path}/out.jpg': _outgoing,
        '${slipDir.path}/in.jpg': _incoming,
        '${slipDir.path}/none.jpg': _noAmount,
      })),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    await slipDir.delete(recursive: true);
  });

  SlipImportController controller() => container.read(slipImportControllerProvider.notifier);
  SlipImportState state() => container.read(slipImportControllerProvider);

  test('scan builds drafts and infers income/expense from owner names', () async {
    await controller().scan(['${slipDir.path}/out.jpg', '${slipDir.path}/in.jpg']);

    final [out, inc] = state().drafts;
    expect(state().isScanning, isFalse);
    expect(out.transaction.type, TransactionType.expense);
    expect(out.transaction.amountSatang, 150000);
    expect(out.transaction.counterparty, 'น.ส. สมหญิง ใจดี');
    expect(out.transaction.counterpartyInstitution, Institution.promptPay);
    expect(inc.transaction.type, TransactionType.income);
    expect(inc.transaction.counterparty, 'นาย สมชาย รักดี');
    expect(inc.transaction.counterpartyInstitution, Institution.scb);
    expect(state().saveableCount, 2);
  });

  test('marks missing amounts and failed reads', () async {
    await controller().scan(['${slipDir.path}/none.jpg', '${slipDir.path}/broken.jpg']);

    expect(state().drafts.map((d) => d.status), [DraftStatus.needsAmount, DraftStatus.failed]);
    expect(state().saveableCount, 0);
  });

  test('editing a draft with an amount makes it saveable', () async {
    await controller().scan(['${slipDir.path}/none.jpg']);
    final draft = state().drafts.single;

    controller().updateDraft(0, draft.withTransaction(draft.transaction.copyWith(amountSatang: 5000)));

    expect(state().drafts.single.status, DraftStatus.ready);
  });

  test('flags the same slip picked twice in one batch as duplicate', () async {
    await controller().scan(['${slipDir.path}/out.jpg', '${slipDir.path}/out.jpg']);

    expect(state().drafts.map((d) => d.status), [DraftStatus.ready, DraftStatus.duplicate]);
  });

  test('saveAll stores transactions with a copied slip image', () async {
    await controller().scan(['${slipDir.path}/out.jpg', '${slipDir.path}/in.jpg']);

    final saved = await controller().saveAll();

    final stored = await container.read(transactionRepositoryProvider).findByMonth(DateTime(2026, 10));
    expect(saved, 2);
    expect(state().drafts, isEmpty);
    expect(stored, hasLength(2));
    for (final tx in stored) {
      expect(File('${slipDir.path}/store/${tx.slipImage}').existsSync(), isTrue);
    }
  });

  test('a slip already in the database is flagged on the next scan', () async {
    await controller().scan(['${slipDir.path}/out.jpg']);
    await controller().saveAll();

    await controller().scan(['${slipDir.path}/out.jpg']);

    expect(state().drafts.single.status, DraftStatus.duplicate);
  });

  test('a slip without a reference is a duplicate when amount and time match a saved one', () async {
    await container.read(transactionRepositoryProvider).create(MoneyTransaction(
          type: TransactionType.expense,
          amountSatang: 150000,
          category: TransactionCategory.transferOut,
          occurredAt: DateTime(2026, 10, 12, 14, 30),
          createdAt: DateTime(2026, 10, 12),
        ));

    await controller().scan(['${slipDir.path}/out.jpg']);

    expect(state().drafts.single.status, DraftStatus.duplicate);
  });

  test('removeDraft drops a draft', () async {
    await controller().scan(['${slipDir.path}/out.jpg', '${slipDir.path}/in.jpg']);

    controller().removeDraft(0);

    expect(state().drafts.single.transaction.type, TransactionType.income);
  });

  group('scanLibrary', () {
    test('turns only slip photos into drafts and tracks progress', () async {
      final outcome = await controller().scanLibrary(since: DateTime(2026, 10, 1));

      expect(outcome, LibraryScanOutcome.completed);
      expect(library.requestedSince, DateTime(2026, 10, 1));
      expect(state().mode, ScanMode.library);
      expect((state().scanned, state().total), (4, 4));
      expect(state().drafts.map((d) => d.transaction.amountSatang), [150000, 20000]);
    });

    test('skips slips that are already saved and counts them', () async {
      await controller().scan(['${slipDir.path}/out.jpg']);
      await controller().saveAll();

      await controller().scanLibrary();

      expect(state().skippedDuplicates, 1);
      expect(state().drafts.single.transaction.type, TransactionType.income);
    });

    test('remembers when a completed search started', () async {
      // Stored with millisecond precision.
      final before = DateTime.now().subtract(const Duration(milliseconds: 1));
      await controller().scanLibrary();

      final last = container.read(settingsRepositoryProvider).lastLibraryScan();
      expect(last, isNotNull);
      expect(last!.isBefore(before), isFalse);
    });

    test('stops when cancelled and does not record the search', () async {
      library.onQuickScan = (id) {
        if (id == 'cat') controller().cancelScan();
      };

      final outcome = await controller().scanLibrary();

      expect(outcome, LibraryScanOutcome.cancelled);
      expect(state().scanned, 2);
      expect(container.read(settingsRepositoryProvider).lastLibraryScan(), isNull);
    });

    test('reports missing photo access without scanning', () async {
      container.dispose();
      container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
        slipDirectoryProvider.overrideWithValue(Directory('${slipDir.path}/store')),
        photoLibrarySourceProvider.overrideWith(
          (ref) => _FakeLibrary(access: PhotoAccess.denied, assets: const [], quick: const {}, exports: const {}),
        ),
      ]);

      expect(await controller().scanLibrary(), LibraryScanOutcome.noAccess);
      expect(state().total, 0);
    });
  });
}
