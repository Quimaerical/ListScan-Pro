import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Database helper singleton that handles SQLite connection lifecycle,
/// table definitions and foreign key constraints.
class SqliteDbHelper {
  static const String _databaseName = 'shopliist_pro.db';
  static const int _databaseVersion = 1;

  static const String tableLists = 'shopping_lists';
  static const String tableItems = 'shopping_items';

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
        is_completed INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (list_id) REFERENCES $tableLists(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_items_list_id ON $tableItems(list_id)');
    await db.execute('CREATE INDEX idx_items_completed ON $tableItems(is_completed)');
  }

  /// Closes database connection safely (useful for testing or app teardown).
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
