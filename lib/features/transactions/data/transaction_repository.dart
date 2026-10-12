import 'package:sqflite/sqflite.dart';

import '../domain/money_transaction.dart';

/// Storage-agnostic access to transactions.
abstract interface class TransactionRepository {
  /// Transactions within the calendar month of [month], newest first.
  Future<List<MoneyTransaction>> findByMonth(DateTime month);

  Future<MoneyTransaction> create(MoneyTransaction transaction);

  Future<MoneyTransaction> update(MoneyTransaction transaction);

  Future<void> delete(int id);

  Future<bool> existsByReference(String reference);
}

/// Thrown when saving a slip whose reference is already stored.
class DuplicateSlipException implements Exception {
  const DuplicateSlipException(this.reference);

  final String reference;

  @override
  String toString() => 'DuplicateSlipException: $reference already saved';
}

class SqliteTransactionRepository implements TransactionRepository {
  const SqliteTransactionRepository(this._db);

  static const table = 'transactions';

  final Database _db;

  @override
  Future<List<MoneyTransaction>> findByMonth(DateTime month) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final rows = await _db.query(
      table,
      where: 'occurred_at >= ? AND occurred_at < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'occurred_at DESC, id DESC',
    );
    return rows.map(MoneyTransaction.fromMap).toList(growable: false);
  }

  @override
  Future<MoneyTransaction> create(MoneyTransaction transaction) async {
    final reference = transaction.reference;
    if (reference != null && await existsByReference(reference)) {
      throw DuplicateSlipException(reference);
    }
    final row = Map.of(transaction.toMap())..remove('id');
    final id = await _db.insert(table, row);
    return transaction.copyWith(id: id);
  }

  @override
  Future<MoneyTransaction> update(MoneyTransaction transaction) async {
    final id = transaction.id;
    if (id == null) throw ArgumentError('Cannot update a transaction without an id');
    final count = await _db.update(table, transaction.toMap(), where: 'id = ?', whereArgs: [id]);
    if (count == 0) throw StateError('Transaction $id not found');
    return transaction;
  }

  @override
  Future<void> delete(int id) => _db.delete(table, where: 'id = ?', whereArgs: [id]);

  @override
  Future<bool> existsByReference(String reference) async {
    final rows = await _db.query(
      table,
      columns: ['id'],
      where: 'reference = ?',
      whereArgs: [reference],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
