import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/expense.dart';

class ExpenseDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> insertExpense(Expense expense) async {
    final db = await _dbHelper.database;
    await db.insert('expenses', expense.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Expense>> getExpensesByUserId(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await _dbHelper.database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Expense>> getExpensesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'date_spent BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  Future<List<Expense>> getRecentExpenses({int limit = 10}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: 'date_spent DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('expenses');

    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  Future<void> bulkInsertExpenses(List<Map<String, dynamic>> expenses, Transaction txn) async {
    for (var expense in expenses) {
      try {
        await txn.insert(
          'expenses',
          expense,
          conflictAlgorithm: ConflictAlgorithm.ignore
        );
      } catch (e) {
        print('Error inserting expense: $expense. Error: $e');
      }
    }
  }

}