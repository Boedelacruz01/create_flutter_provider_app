import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:noteapp/models/todo_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'todo.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos (
        id TEXT PRIMARY KEY,
        task TEXT,
        extraNote TEXT,
        complete INTEGER
      )
    ''');
  }

  // Insert or update a todo
  Future<void> insertTodo(Map<String, dynamic> todoMap) async {
    final db = await database;
    await db.insert(
      'todos',
      todoMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all todos from SQLite
  Future<List<Map<String, dynamic>>> getTodos() async {
    final db = await database;
    return await db.query('todos');
  }

  // 🔁 Delete a single todo by ID
  Future<void> deleteTodo(String id) async {
    final db = await database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  // Clear all local todos (useful before syncing fresh from Firebase)
  Future<void> clearTodos() async {
    final db = await database;
    await db.delete('todos');
  }

  // (Optional) Get as TodoModel list directly
  Future<List<TodoModel>> getTodosAsModels() async {
    final todoMaps = await getTodos();
    return todoMaps.map((map) => TodoModel.fromSqliteMap(map)).toList();
  }
}
