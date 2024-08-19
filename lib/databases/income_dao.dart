import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/income.dart';

class IncomeDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> insertIncome(Income income) async {
    final db = await _dbHelper.database;
    await db.insert('incomes', income.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Income>> getIncomesByUserId(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'incomes',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) {
      return Income.fromMap(maps[i]);
    });
  }

  Future<void> updateIncome(Income income) async {
    final db = await _dbHelper.database;
    await db.update(
      'incomes',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<void> deleteIncome(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'incomes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<List<Income>> getIncomesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'incomes',
      where: 'date_received BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return List.generate(maps.length, (i) {
      return Income.fromMap(maps[i]);
    });
  }

  Future<List<Income>> getRecentIncomes({int limit = 5}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'incomes',
      orderBy: 'date_received DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return Income.fromMap(maps[i]);
    });
  }

  Future<List<Income>> getAllIncomes() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('incomes');

    return List.generate(maps.length, (i) {
      return Income.fromMap(maps[i]);
    });
  }

  Future<void> bulkInsertIncomes(List<Map<String, dynamic>> incomes, Transaction txn) async {
    for (var income in incomes) {
      try {
        await txn.insert(
          'incomes',
          income,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } catch (e) {
        print('Error inserting income: $income. Error: $e');
      }
    }
  }

}
