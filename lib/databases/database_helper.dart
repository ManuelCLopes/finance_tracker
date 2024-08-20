import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'finance_tracker.db');
    return await openDatabase(
      path,
      version: 2, // Update version number if schema changes
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      await _dropTables(db);
      await _createTables(db);
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE income_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE incomes (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        category_id INTEGER,
        amount REAL,
        date_received TEXT,
        tax_amount REAL,
        FOREIGN KEY(category_id) REFERENCES income_categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        category_id INTEGER,
        amount REAL,
        date_spent TEXT,
        FOREIGN KEY(category_id) REFERENCES expense_categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE investments (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        investment_type TEXT,
        initial_value REAL,
        current_value REAL,
        date_invested TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE savings (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        goal_name TEXT,
        target_amount REAL,
        current_amount REAL,
        date_goal_set TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE net_worth (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        date_calculated TEXT,
        net_worth REAL
      )
    ''');
  }

  Future<void> _dropTables(Database db) async {
    await db.execute('DROP TABLE IF EXISTS income_categories');
    await db.execute('DROP TABLE IF EXISTS expense_categories');
    await db.execute('DROP TABLE IF EXISTS incomes');
    await db.execute('DROP TABLE IF EXISTS expenses');
    await db.execute('DROP TABLE IF EXISTS investments');
    await db.execute('DROP TABLE IF EXISTS savings');
    await db.execute('DROP TABLE IF EXISTS net_worth');
  }

  Future<void> bulkInsert(
      String tableName, List<Map<String, dynamic>> data, Transaction txn) async {
    for (var row in data) {
      await txn.insert(tableName, row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}