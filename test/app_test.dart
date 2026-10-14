import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jod_slip/app.dart';
import 'package:jod_slip/core/database/app_database.dart';
import 'package:jod_slip/core/institution/institution.dart';
import 'package:jod_slip/core/institution/institution_avatar.dart';
import 'package:jod_slip/core/providers.dart';
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

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        slipDirectoryProvider.overrideWithValue(Directory.systemTemp),
      ],
      child: const JodSlipApp(),
    ));
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
}

/// Seeds the database through the real repository.
class SqliteTransactionRepositoryHelper {
  static Future<void> seed(Database db, DateTime now) async {
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    final repository = container.read(transactionRepositoryProvider);
    await repository.create(MoneyTransaction(
      type: TransactionType.expense,
      amountSatang: 8900,
      category: TransactionCategory.food,
      occurredAt: DateTime(now.year, now.month, 1, 12),
      createdAt: now,
      counterpartyInstitution: Institution.promptPay,
    ));
    await repository.create(MoneyTransaction(
      type: TransactionType.income,
      amountSatang: 3000000,
      category: TransactionCategory.salary,
      occurredAt: DateTime(now.year, now.month, 1, 9),
      createdAt: now,
    ));
    container.dispose();
  }
}
