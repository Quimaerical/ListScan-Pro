import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Database helper singleton that handles SQLite connection lifecycle,
/// table definitions and foreign key constraints.
class SqliteDbHelper {
  static const String _databaseName = 'shopliist_pro.db';
  static const int _databaseVersion = 2;

  static const String tableLists = 'shopping_lists';
  static const String tableItems = 'shopping_items';
  static const String tableSettings = 'app_settings';

  static Database? _database;

  SqliteDbHelper._();
  static final SqliteDbHelper instance = SqliteDbHelper._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String databasesPath = await getDatabasesPath();
    final String path = p.join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable SQLite foreign keys cascade
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableLists (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        color_index INTEGER NOT NULL DEFAULT 0,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableItems (
        id TEXT PRIMARY KEY,
        list_id TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity TEXT,
        category TEXT,
        amount INTEGER NOT NULL DEFAULT 1,
        is_separator INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (list_id) REFERENCES $tableLists(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_items_list_id ON $tableItems(list_id)');
    await db.execute(
      'CREATE INDEX idx_items_completed ON $tableItems(is_completed)',
    );

    await _createSettingsTable(db);
  }

  /// Incremental, non-destructive migrations. Each step only runs when
  /// upgrading *through* its version, so user data is always preserved.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $tableItems ADD COLUMN amount INTEGER NOT NULL DEFAULT 1',
      );
      await db.execute(
        'ALTER TABLE $tableItems ADD COLUMN is_separator INTEGER NOT NULL DEFAULT 0',
      );

      // Legacy rows whose quantity was a bare integer ("3") become the counter.
      await db.execute('''
        UPDATE $tableItems
        SET amount = CAST(quantity AS INTEGER), quantity = NULL
        WHERE quantity GLOB '[0-9]*'
          AND quantity NOT GLOB '*[^0-9]*'
          AND CAST(quantity AS INTEGER) > 0
      ''');

      await _createSettingsTable(db);
    }
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSettings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// Closes database connection safely (useful for testing or app teardown).
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
