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
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
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
        symbol TEXT,
        investment_type TEXT,
        initial_value REAL,
        current_value REAL,
        date_invested TEXT,
        investment_product TEXT,
        quantity REAL,
        annual_return REAL,
        duration TEXT
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

 Future<List<Map<String, dynamic>>> getAllExpenses() async {
  final db = await database;
  return await db.rawQuery('''
    SELECT 
      --expenses.id, 
      expense_categories.name AS category,
      ROUND(expenses.amount, 2) as amount, 
      expenses.date_spent 
    FROM expenses
    JOIN expense_categories ON expenses.category_id = expense_categories.id
  ''');
}

Future<List<Map<String, dynamic>>> getAllIncomes() async {
  final db = await database;
  return await db.rawQuery('''
    SELECT 
      --incomes.id, 
      income_categories.name AS category,
      ROUND(incomes.amount, 2) as amount, 
      incomes.date_received, 
      incomes.tax_amount 
    FROM incomes
    JOIN income_categories ON incomes.category_id = income_categories.id 
  ''');
}

Future<List<Map<String, dynamic>>> getAllInvestments() async {
  final db = await database;
  return await db.rawQuery('''
    SELECT 
      --investments.id, 
      investments.symbol,
      investments.investment_type, 
      investments.date_invested,
      ROUND(investments.initial_value, 2) AS initial_value, 
      ROUND(investments.current_value, 2) AS current_value,
      investments.investment_product
    FROM investments
  ''');
  }



  Future<void> bulkInsert(
      String tableName, List<Map<String, dynamic>> data, Transaction txn) async {
    for (var row in data) {
      await txn.insert(tableName, row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}
