import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/player.dart';

/// Wraps the local SQLite database that stores favorite players.
///
/// Table `favorites` — one row per saved player:
///   id INTEGER PRIMARY KEY   (the MLB player id; prevents duplicates)
///   fullName TEXT
///   jerseyNumber TEXT
///   position TEXT
///   batSide TEXT, throwSide TEXT, birthCountry TEXT, height TEXT
///   weight INTEGER
///   note TEXT                 (user's personal note about the player)
///   savedAt INTEGER           (millisecondsSinceEpoch the row was added)
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'braves_favorites.db';
  static const _dbVersion = 1;
  static const table = 'favorites';

  Database? _db;

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final dbDir = await getDatabasesPath();
    final path = p.join(dbDir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $table (
            id INTEGER PRIMARY KEY,
            fullName TEXT NOT NULL,
            jerseyNumber TEXT,
            position TEXT,
            batSide TEXT,
            throwSide TEXT,
            birthCountry TEXT,
            height TEXT,
            weight INTEGER,
            note TEXT,
            savedAt INTEGER
          )
        ''');
      },
    );
  }

  /// Inserts (or replaces) a favorite. Using the player id as PK + REPLACE
  /// means saving the same player twice just updates it — no duplicates.
  Future<void> savePlayer(Player player) async {
    final db = await database;
    await db.insert(
      table,
      player.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns all saved players, newest first.
  Future<List<Player>> getFavorites() async {
    final db = await database;
    final rows = await db.query(table, orderBy: 'savedAt DESC');
    return rows.map(Player.fromMap).toList();
  }

  Future<bool> isFavorite(int id) async {
    final db = await database;
    final rows = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Returns the set of saved ids — handy for marking the roster list.
  Future<Set<int>> getFavoriteIds() async {
    final db = await database;
    final rows = await db.query(table, columns: ['id']);
    return rows.map((r) => r['id'] as int).toSet();
  }

  Future<void> updateNote(int id, String note) async {
    final db = await database;
    await db.update(
      table,
      {'note': note},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePlayer(int id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearAll() async {
    final db = await database;
    return db.delete(table);
  }
}
