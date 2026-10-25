import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/expense.dart';

/// SQLite persistence layer (sqflite_common_ffi + system libsqlite3).
class ExpenseDatabase {
  ExpenseDatabase._(this._path);
  static final ExpenseDatabase instance = ExpenseDatabase._(null);

  /// In-memory database for tests.
  factory ExpenseDatabase.inMemory() => ExpenseDatabase._(inMemoryDatabasePath);

  final String? _path;
  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    sqfliteFfiInit();
    var path = _path;
    if (path == null) {
      final dir = await getApplicationSupportDirectory();
      await Directory(dir.path).create(recursive: true);
      path = p.join(dir.path, 'expenses.db');
    }
    _db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            merchant TEXT NOT NULL,
            amount_vnd INTEGER NOT NULL,
            date INTEGER NOT NULL,
            category TEXT NOT NULL,
            thumbnail_path TEXT,
            note TEXT
          )
        '''),
      ),
    );
    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<int> insert(Expense e) async =>
      (await _database).insert('expenses', e.toMap()..remove('id'));

  Future<int> update(Expense e) async => (await _database)
      .update('expenses', e.toMap(), where: 'id = ?', whereArgs: [e.id]);

  Future<int> delete(int id) async =>
      (await _database).delete('expenses', where: 'id = ?', whereArgs: [id]);

  Future<List<Expense>> all() async {
    final rows = await (await _database).query('expenses', orderBy: 'date DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<List<Expense>> between(DateTime from, DateTime to) async {
    final rows = await (await _database).query(
      'expenses',
      where: 'date >= ? AND date < ?',
      whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }
}
