import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hydroponic_users.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE users (
  id $idType,
  name $textType,
  email $textType UNIQUE,
  password $textType
  )
''');
  }

  Future<int> registerUser(String name, String email, String password) async {
    final db = await instance.database;

    final data = {
      'name': name,
      'email': email,
      'password': password,
    };

    try {
      final id = await db.insert('users', data);
      return id;
    } catch (e) {
      // Insertion failed likely due to email uniqueness constraint
      return -1;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await instance.database;

    final maps = await db.query(
      'users',
      columns: ['id', 'name', 'email'],
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null; // Login failed
    }
  }

  Future<bool> checkEmailExists(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty;
  }

  Future<bool> updatePassword(String email, String newPassword) async {
    final db = await instance.database;
    final rowsAffected = await db.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );
    return rowsAffected > 0;
  }
}
