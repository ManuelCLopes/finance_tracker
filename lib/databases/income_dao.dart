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

  Future<void> insertOrUpdateTransaction(Map<String, dynamic> incomeData, Database db) async {
    try {
      if (incomeData['id'] == null) {
        incomeData['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      }
      final List<Map<String, dynamic>> existingIncomes = await db.query(
        'incomes',
        where: 'id = ?',
        whereArgs: [incomeData['id']],
      );

      if (existingIncomes.isNotEmpty) {
        await db.update(
          'incomes',
          incomeData,
          where: 'id = ?',
          whereArgs: [incomeData['id']],
        );
      } else {
        await db.insert(
          'incomes',
          incomeData,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    } catch (e) {
      print('Error inserting or updating income: $e');
    }
  }

}
