import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/meal_entry.dart';

class LocalStorageException implements Exception {
  final String message;
  final Object? cause;
  LocalStorageException(this.message, [this.cause]);

  @override
  String toString() => 'LocalStorageException: $message';
}

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _dbName = 'bitacora_comidas.db';
  static const int _dbVersion = 1;
  static const String table = 'entries';

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);
      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _onCreate,
      );
    } catch (e) {
      throw LocalStorageException('No se pudo abrir la base de datos', e);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        notes TEXT,
        image_path TEXT,
        latitude REAL,
        longitude REAL,
        created_at TEXT NOT NULL
      )
    ''');
  }


  Future<int> insert(MealEntry entry) async {
    try {
      final db = await database;
      return await db.insert(table, entry.toMap()..remove('id'));
    } catch (e) {
      throw LocalStorageException('No se pudo guardar la entrada', e);
    }
  }

  Future<List<MealEntry>> getAll() async {
    try {
      final db = await database;
      final rows = await db.query(table, orderBy: 'created_at DESC');
      return rows.map(MealEntry.fromMap).toList();
    } catch (e) {
      throw LocalStorageException('No se pudieron cargar las entradas', e);
    }
  }

  Future<MealEntry?> getById(int id) async {
    try {
      final db = await database;
      final rows = await db.query(table, where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) return null;
      return MealEntry.fromMap(rows.first);
    } catch (e) {
      throw LocalStorageException('No se pudo cargar la entrada', e);
    }
  }

  Future<int> update(MealEntry entry) async {
    try {
      final db = await database;
      return await db.update(
        table,
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    } catch (e) {
      throw LocalStorageException('No se pudo actualizar la entrada', e);
    }
  }

  Future<int> delete(int id) async {
    try {
      final db = await database;
      return await db.delete(table, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw LocalStorageException('No se pudo eliminar la entrada', e);
    }
  }
}