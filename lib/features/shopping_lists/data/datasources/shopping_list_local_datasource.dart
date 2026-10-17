import 'package:sqflite/sqflite.dart';
import '../../domain/models/shopping_item.dart';
import '../../domain/models/shopping_list.dart';
import 'sqlite_db_helper.dart';

/// Data source executing SQLite queries directly on the local database.
class ShoppingListLocalDataSource {
  final SqliteDbHelper dbHelper;

  ShoppingListLocalDataSource({SqliteDbHelper? dbHelper})
      : dbHelper = dbHelper ?? SqliteDbHelper.instance;

  Future<Database> get _db => dbHelper.database;

  Future<List<ShoppingList>> getLists({bool includeArchived = false}) async {
    final Database db = await _db;

    final String whereClause = includeArchived ? '' : 'WHERE is_archived = 0';
    final List<Map<String, dynamic>> listRows = await db.rawQuery('''
      SELECT * FROM ${SqliteDbHelper.tableLists}
      $whereClause
      ORDER BY is_pinned DESC, updated_at DESC
    ''');

    final List<ShoppingList> result = <ShoppingList>[];

    for (final Map<String, dynamic> row in listRows) {
      final String listId = row['id'] as String;
      final List<Map<String, dynamic>> itemRows = await db.query(
        SqliteDbHelper.tableItems,
        where: 'list_id = ?',
        whereArgs: <dynamic>[listId],
        orderBy: 'is_completed ASC, sort_order ASC, created_at ASC',
      );

      final List<ShoppingItem> items = itemRows.map(ShoppingItem.fromMap).toList();
      result.add(ShoppingList.fromMap(row, items));
    }

    return result;
  }

  Future<ShoppingList?> getListById(String id) async {
    final Database db = await _db;

    final List<Map<String, dynamic>> listRows = await db.query(
      SqliteDbHelper.tableLists,
      where: 'id = ?',
      whereArgs: <dynamic>[id],
      limit: 1,
    );

    if (listRows.isEmpty) return null;

    final List<Map<String, dynamic>> itemRows = await db.query(
      SqliteDbHelper.tableItems,
      where: 'list_id = ?',
      whereArgs: <dynamic>[id],
      orderBy: 'is_completed ASC, sort_order ASC, created_at ASC',
    );

    final List<ShoppingItem> items = itemRows.map(ShoppingItem.fromMap).toList();
    return ShoppingList.fromMap(listRows.first, items);
  }

  Future<void> saveList(ShoppingList list) async {
    final Database db = await _db;
    await db.insert(
      SqliteDbHelper.tableLists,
      list.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteList(String id) async {
    final Database db = await _db;
    await db.delete(
      SqliteDbHelper.tableLists,
      where: 'id = ?',
      whereArgs: <dynamic>[id],
    );
  }

  Future<void> togglePinList(String id) async {
    final Database db = await _db;
    await db.rawUpdate('''
      UPDATE ${SqliteDbHelper.tableLists}
      SET is_pinned = CASE WHEN is_pinned = 1 THEN 0 ELSE 1 END,
          updated_at = ?
      WHERE id = ?
    ''', <dynamic>[DateTime.now().toIso8601String(), id]);
  }

  Future<void> setArchived(String id, bool isArchived) async {
    final Database db = await _db;
    await db.update(
      SqliteDbHelper.tableLists,
      <String, dynamic>{
        'is_archived': isArchived ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <dynamic>[id],
    );
  }

  Future<void> saveItem(ShoppingItem item) async {
    final Database db = await _db;
    await db.transaction((Transaction txn) async {
      await txn.insert(
        SqliteDbHelper.tableItems,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Touch the parent list's updated_at timestamp
      await txn.update(
        SqliteDbHelper.tableLists,
        <String, dynamic>{
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: <dynamic>[item.listId],
      );
    });
  }

  Future<void> deleteItem(String id) async {
    final Database db = await _db;
    await db.delete(
      SqliteDbHelper.tableItems,
      where: 'id = ?',
      whereArgs: <dynamic>[id],
    );
  }

  Future<void> toggleItemCompleted(String id, bool isCompleted) async {
    final Database db = await _db;
    await db.update(
      SqliteDbHelper.tableItems,
      <String, dynamic>{
        'is_completed': isCompleted ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: <dynamic>[id],
    );
  }
}
