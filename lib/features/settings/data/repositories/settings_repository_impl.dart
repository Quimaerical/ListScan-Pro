import 'package:sqflite/sqflite.dart';
import '../../../shopping_lists/data/datasources/sqlite_db_helper.dart';
import '../../domain/repositories/settings_repository.dart';

/// SQLite-backed implementation of [SettingsRepository] that shares the
/// app database through [SqliteDbHelper] (table `app_settings`).
class SqliteSettingsRepository implements SettingsRepository {
  final SqliteDbHelper dbHelper;

  SqliteSettingsRepository({SqliteDbHelper? dbHelper})
    : dbHelper = dbHelper ?? SqliteDbHelper.instance;

  @override
  Future<Map<String, String>> loadAll() async {
    final Database db = await dbHelper.database;
    final List<Map<String, dynamic>> rows = await db.query(
      SqliteDbHelper.tableSettings,
    );

    return <String, String>{
      for (final Map<String, dynamic> row in rows)
        row['key'] as String: row['value'] as String,
    };
  }

  @override
  Future<void> setValue(String key, String value) async {
    final Database db = await dbHelper.database;
    await db.insert(SqliteDbHelper.tableSettings, <String, dynamic>{
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

/// In-memory implementation used by tests or as a safe fallback.
class InMemorySettingsRepository implements SettingsRepository {
  final Map<String, String> _store;

  InMemorySettingsRepository([Map<String, String>? initial])
    : _store = <String, String>{...?initial};

  @override
  Future<Map<String, String>> loadAll() async =>
      Map<String, String>.unmodifiable(_store);

  @override
  Future<void> setValue(String key, String value) async => _store[key] = value;
}
