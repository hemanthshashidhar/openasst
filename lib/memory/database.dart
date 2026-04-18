import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/constants.dart';

class OrbDatabase {
  static final OrbDatabase instance = OrbDatabase._internal();
  static Database? _db;

  OrbDatabase._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<void> init() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, Constants.dbName);

    return await openDatabase(
      path,
      version: Constants.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Messages table
    await db.execute('''
      CREATE TABLE ${Constants.messagesTable} (
        id TEXT PRIMARY KEY,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        session_id TEXT NOT NULL,
        provider TEXT,
        model TEXT
      )
    ''');

    // Documents table
    await db.execute('''
      CREATE TABLE ${Constants.documentsTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        path TEXT NOT NULL,
        content TEXT NOT NULL,
        added_at INTEGER NOT NULL
      )
    ''');

    // Key-value settings table (non-sensitive)
    await db.execute('''
      CREATE TABLE ${Constants.settingsTable} (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ─── Messages ────────────────────────────────────────────────────────────

  Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    await db.insert(
      Constants.messagesTable,
      message,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getMessages({
    String? sessionId,
    int limit = 50,
  }) async {
    final db = await database;
    if (sessionId != null) {
      return await db.query(
        Constants.messagesTable,
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'timestamp ASC',
        limit: limit,
      );
    }
    return await db.query(
      Constants.messagesTable,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getRecentMessages(int count) async {
    final db = await database;
    return await db.query(
      Constants.messagesTable,
      orderBy: 'timestamp DESC',
      limit: count,
    );
  }

  Future<void> deleteMessage(String id) async {
    final db = await database;
    await db.delete(
      Constants.messagesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllMessages() async {
    final db = await database;
    await db.delete(Constants.messagesTable);
  }

  // ─── Documents ───────────────────────────────────────────────────────────

  Future<void> insertDocument(Map<String, dynamic> doc) async {
    final db = await database;
    await db.insert(
      Constants.documentsTable,
      doc,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getDocuments() async {
    final db = await database;
    return await db.query(
      Constants.documentsTable,
      orderBy: 'added_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getDocument(String id) async {
    final db = await database;
    final results = await db.query(
      Constants.documentsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> deleteDocument(String id) async {
    final db = await database;
    await db.delete(
      Constants.documentsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── Settings ────────────────────────────────────────────────────────────

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      Constants.settingsTable,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      Constants.settingsTable,
      where: 'key = ?',
      whereArgs: [key],
    );
    return results.isNotEmpty ? results.first['value'] as String? : null;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
