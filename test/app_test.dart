import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jod_slip/app.dart';
import 'package:jod_slip/core/database/app_database.dart';
import 'package:jod_slip/core/institution/institution.dart';
import 'package:jod_slip/core/institution/institution_avatar.dart';
import 'package:jod_slip/core/launch/launch_actions.dart';
import 'package:jod_slip/core/providers.dart';
import 'package:jod_slip/features/slip_scan/application/slip_import_controller.dart';
import 'package:jod_slip/features/slip_scan/data/photo_library_source.dart';
import 'package:jod_slip/features/slip_scan/data/slip_recognizer.dart';
import 'package:jod_slip/features/transactions/domain/money_transaction.dart';
import 'package:jod_slip/features/transactions/domain/transaction_category.dart';
import 'package:jod_slip/features/transactions/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late SharedPreferences prefs;

  setUpAll(() async {
    sqfliteFfiInit();
    await initializeDateFormatting('th');
    await initializeDateFormatting('en');
  });

  setUp(() async {
    // FFI database work must run outside the fake-async test zone.
    db = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester, {LaunchActionSource? launchActions}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (launchActions != null) launchActionSourceProvider.overrideWithValue(launchActions),
          photoLibrarySourceProvider.overrideWithValue(const _AuthorizedLibrary()),
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          slipDirectoryProvider.overrideWithValue(Directory.systemTemp),
        ],
        child: const JodSlipApp(),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }

  testWidgets('home shows the Thai title and empty state', (tester) async {
    await pumpApp(tester);

    expect(find.text('จดสลิป'), findsOneWidget);
    expect(find.text('ยังไม่มีรายการในเดือนนี้'), findsOneWidget);
    expect(find.text('สแกนสลิป'), findsOneWidget);
  });

  testWidgets('home lists this month\'s transactions with a summary', (tester) async {
    final now = DateTime.now();
    await tester.runAsync(() => SqliteTransactionRepositoryHelper.seed(db, now));
    await pumpApp(tester);

    expect(find.text('อาหาร/เครื่องดื่ม'), findsOneWidget);
    expect(find.text('-฿89.00'), findsOneWidget);
    expect(find.text('เงินเดือน'), findsOneWidget);
    // Slip transactions show the other party's institution; manual ones the category icon.
    expect(find.byType(InstitutionAvatar), findsOneWidget);
    expect(find.text('PromptPay'), findsOneWidget);
    expect(find.byIcon(Icons.work), findsOneWidget);
  });

  testWidgets('scan sheet offers photos, camera and manual entry', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('สแกนสลิป'));
    await tester.pumpAndSettle();

    expect(find.text('เลือกสลิปจากรูปภาพ'), findsOneWidget);
    expect(find.text('ถ่ายรูปสลิป'), findsOneWidget);
    expect(find.text('เพิ่มรายการเอง'), findsOneWidget);
  });

  testWidgets('settings saves owner names and switches language', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('เพิ่มชื่อ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'พีรพล ชื่นใจ');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    expect(find.text('พีรพล ชื่นใจ'), findsOneWidget);
    expect(prefs.getStringList('owner_names'), ['พีรพล ชื่นใจ']);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('app bar button starts the photo-library search', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('ค้นหาสลิปจากรูปทั้งหมด'));
    await tester.pumpAndSettle();

    expect(find.text('ค้นหาจากรูปช่วงไหน'), findsOneWidget);
  });

  testWidgets('home-screen widget launch action starts the photo-library search', (tester) async {
    final launchActions = _FakeLaunchActions();
    await pumpApp(tester, launchActions: launchActions);
    expect(find.text('ค้นหาจากรูปช่วงไหน'), findsNothing);

    launchActions.send(LaunchAction.scanLibrary);
    await tester.pumpAndSettle();

    expect(find.text('ค้นหาจากรูปช่วงไหน'), findsOneWidget);
  });

  testWidgets('launch action is ignored while another screen is open', (tester) async {
    final launchActions = _FakeLaunchActions();
    await pumpApp(tester, launchActions: launchActions);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    launchActions.send(LaunchAction.scanLibrary);
    await tester.pumpAndSettle();

    expect(find.text('ค้นหาจากรูปช่วงไหน'), findsNothing);
  });
}

/// Seeds the database through the real repository.
class SqliteTransactionRepositoryHelper {
  static Future<void> seed(Database db, DateTime now) async {
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    final repository = container.read(transactionRepositoryProvider);
    await repository.create(
      MoneyTransaction(
        type: TransactionType.expense,
        amountSatang: 8900,
        category: TransactionCategory.food,
        occurredAt: DateTime(now.year, now.month, 1, 12),
        createdAt: now,
        counterpartyInstitution: Institution.promptPay,
      ),
    );
    await repository.create(
      MoneyTransaction(
        type: TransactionType.income,
        amountSatang: 3000000,
        category: TransactionCategory.salary,
        occurredAt: DateTime(now.year, now.month, 1, 9),
        createdAt: now,
      ),
    );
    container.dispose();
  }
}

class _FakeLaunchActions implements LaunchActionSource {
  void Function(LaunchAction action)? _onAction;

  void send(LaunchAction action) => _onAction!(action);

  @override
  void listen(void Function(LaunchAction action) onAction) => _onAction = onAction;
}

/// Grants access; the tests stop at the range dialog, before anything is read.
class _AuthorizedLibrary implements PhotoLibrarySource {
  const _AuthorizedLibrary();

  @override
  Future<PhotoAccess> requestAccess() async => PhotoAccess.authorized;

  @override
  Future<List<PhotoAsset>> listImages({DateTime? since}) => throw UnimplementedError();

  @override
  Future<RecognizedSlip> quickScan(String assetId) => throw UnimplementedError();

  @override
  Future<String> export(String assetId) => throw UnimplementedError();

  @override
  Future<void> openSettings() async {}
}
