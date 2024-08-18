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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT
      )
    ''');

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
        source TEXT,
        amount REAL,
        date_received TEXT,
        tax_amount REAL,
        FOREIGN KEY(user_id) REFERENCES users(id),
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
        FOREIGN KEY(user_id) REFERENCES users(id),
        FOREIGN KEY(category_id) REFERENCES expense_categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE savings (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        goal_name TEXT,
        target_amount REAL,
        current_amount REAL,
        date_goal_set TEXT,
        FOREIGN KEY(user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE investments (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        investment_type TEXT,
        initial_value REAL,
        current_value REAL,
        date_invested TEXT,
        FOREIGN KEY(user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE net_worth (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        date_calculated TEXT,
        net_worth REAL,
        FOREIGN KEY(user_id) REFERENCES users(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Step 1: Create the new table with the correct structure
    await db.execute('''
      CREATE TABLE new_incomes (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        category_id TEXT,
        source TEXT,
        amount REAL,
        date_received TEXT,
        tax_amount REAL,
        FOREIGN KEY(user_id) REFERENCES users(id),
        FOREIGN KEY(category_id) REFERENCES income_categories(id)
      )
    ''');

    // Step 2: Copy the data from the old table to the new table
    await db.execute('''
      INSERT INTO new_incomes (id, user_id, source, amount, date_received, tax_amount)
      SELECT id, user_id, source, amount, date_received, tax_amount FROM incomes
    ''');

    // Step 3: Drop the old table
    await db.execute('DROP TABLE incomes');

    // Step 4: Rename the new table to the old table name
    await db.execute('ALTER TABLE new_incomes RENAME TO incomes');
  }
}


}
