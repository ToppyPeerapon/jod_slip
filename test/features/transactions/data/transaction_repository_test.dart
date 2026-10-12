import 'package:flutter_test/flutter_test.dart';
import 'package:jod_slip/core/database/app_database.dart';
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
    ));

    final [loaded] = await repository.findByMonth(DateTime(2026, 10));
    expect(created.id, isNotNull);
    expect(loaded.id, created.id);
    expect(loaded.note, 'ข้าวมันไก่');
    expect(loaded.counterparty, 'ร้านป้า');
    expect(loaded.bankCode, '004');
    expect(loaded.reference, 'REF1234567890');
    expect(loaded.slipImage, 'slip.jpg');
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
}
