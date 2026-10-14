import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import 'package:jod_slip/core/database/app_database.dart';
import 'package:jod_slip/core/institution/institution.dart';
import 'package:jod_slip/features/transactions/data/transaction_repository.dart';
import 'package:jod_slip/features/transactions/domain/money_transaction.dart';
import 'package:jod_slip/features/transactions/domain/transaction_category.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

MoneyTransaction _tx({
  DateTime? occurredAt,
  String? reference,
  int amountSatang = 10000,
  TransactionType type = TransactionType.expense,
}) =>
    MoneyTransaction(
      type: type,
      amountSatang: amountSatang,
      category: TransactionCategory.defaultFor(type),
      occurredAt: occurredAt ?? DateTime(2026, 10, 12, 10),
      createdAt: DateTime(2026, 10, 12, 10),
      reference: reference,
    );

void main() {
  late Database db;
  late SqliteTransactionRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    repository = SqliteTransactionRepository(db);
  });

  tearDown(() => db.close());

  test('create assigns an id and round-trips all fields', () async {
    final created = await repository.create(_tx(reference: 'REF1234567890').copyWith(
      note: 'ข้าวมันไก่',
      counterparty: () => 'ร้านป้า',
      bankCode: () => '004',
      slipImage: () => 'slip.jpg',
      counterpartyInstitution: () => Institution.promptPay,
    ));

    final [loaded] = await repository.findByMonth(DateTime(2026, 10));
    expect(created.id, isNotNull);
    expect(loaded.id, created.id);
    expect(loaded.note, 'ข้าวมันไก่');
    expect(loaded.counterparty, 'ร้านป้า');
    expect(loaded.bankCode, '004');
    expect(loaded.reference, 'REF1234567890');
    expect(loaded.slipImage, 'slip.jpg');
    expect(loaded.counterpartyInstitution, Institution.promptPay);
    expect(loaded.category, TransactionCategory.transferOut);
  });

  test('findByMonth only returns that month, newest first', () async {
    await repository.create(_tx(occurredAt: DateTime(2026, 9, 30, 23, 59)));
    await repository.create(_tx(occurredAt: DateTime(2026, 10, 1)));
    await repository.create(_tx(occurredAt: DateTime(2026, 10, 31, 23, 59)));
    await repository.create(_tx(occurredAt: DateTime(2026, 11, 1)));

    final october = await repository.findByMonth(DateTime(2026, 10, 15));

    expect(october.map((t) => t.occurredAt), [DateTime(2026, 10, 31, 23, 59), DateTime(2026, 10, 1)]);
  });

  test('create rejects a duplicate slip reference', () async {
    await repository.create(_tx(reference: 'DUP1234567890'));

    expect(
      () => repository.create(_tx(reference: 'DUP1234567890')),
      throwsA(isA<DuplicateSlipException>()),
    );
    expect(await repository.existsByReference('DUP1234567890'), isTrue);
  });

  test('allows many transactions without a reference', () async {
    await repository.create(_tx());
    await repository.create(_tx());
    expect(await repository.findByMonth(DateTime(2026, 10)), hasLength(2));
  });

  test('update and delete', () async {
    final created = await repository.create(_tx());
    await repository.update(created.copyWith(amountSatang: 55000, type: TransactionType.income));

    final [updated] = await repository.findByMonth(DateTime(2026, 10));
    expect(updated.amountSatang, 55000);
    expect(updated.type, TransactionType.income);

    await repository.delete(created.id!);
    expect(await repository.findByMonth(DateTime(2026, 10)), isEmpty);
  });

  test('update without an id throws', () {
    expect(() => repository.update(_tx()), throwsArgumentError);
  });

  test('upgrading a v1 database keeps rows and adds the institution column', () async {
    final dir = await Directory.systemTemp.createTemp('db_upgrade');
    final path = '${dir.path}/v1.db';
    final v1 = await databaseFactoryFfi.openDatabase(path, options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT NOT NULL, amount_satang INTEGER NOT NULL,
          category TEXT NOT NULL, occurred_at INTEGER NOT NULL, created_at INTEGER NOT NULL,
          note TEXT NOT NULL DEFAULT '', counterparty TEXT, bank_code TEXT, reference TEXT UNIQUE, slip_image TEXT
        )'''),
    ));
    await v1.insert('transactions', {
      'type': 'expense', 'amount_satang': 100, 'category': 'food',
      'occurred_at': DateTime(2026, 10, 1).millisecondsSinceEpoch, 'created_at': 0,
    });
    await v1.close();

    final upgraded = await AppDatabase.open(factory: databaseFactoryFfi, path: path);
    final [row] = await SqliteTransactionRepository(upgraded).findByMonth(DateTime(2026, 10));
    expect(row.amountSatang, 100);
    expect(row.counterpartyInstitution, isNull);

    await upgraded.close();
    await dir.delete(recursive: true);
  });
}
