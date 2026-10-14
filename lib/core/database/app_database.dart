import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens the local SQLite database and applies schema migrations.
class AppDatabase {
  const AppDatabase._();

  static const fileName = 'jod_slip.db';
  static const _version = 2;

  /// [factory] and [path] are injectable so tests can use an in-memory
  /// FFI database.
  static Future<Database> open({DatabaseFactory? factory, String? path}) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await dbFactory.getDatabasesPath(), fileName);
    return dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(version: _version, onCreate: _onCreate, onUpgrade: _onUpgrade),
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
        amount_satang INTEGER NOT NULL CHECK (amount_satang > 0),
        category TEXT NOT NULL,
        occurred_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        counterparty TEXT,
        bank_code TEXT,
        reference TEXT UNIQUE,
        slip_image TEXT,
        counterparty_institution TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_transactions_occurred_at ON transactions (occurred_at)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN counterparty_institution TEXT');
    }
  }
}
