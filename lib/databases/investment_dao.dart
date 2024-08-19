import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/investment.dart';

class InvestmentDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> insertInvestment(Investment investment) async {
    final db = await _dbHelper.database;
    await db.insert('investments', investment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Investment>> getInvestmentsByUserId(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'investments',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) {
      return Investment.fromMap(maps[i]);
    });
  }

  Future<void> updateInvestment(Investment investment) async {
    final db = await _dbHelper.database;
    await db.update(
      'investments',
      investment.toMap(),
      where: 'id = ?',
      whereArgs: [investment.id],
    );
  }

  Future<void> deleteInvestment(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'investments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Investment>> getAllInvestments() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('investments');

    return List.generate(maps.length, (i) {
      return Investment.fromMap(maps[i]);
    });
  }

  Future<void> bulkInsertInvestments(List<Map<String, dynamic>> investments, Transaction txn) async {
    for (var investment in investments) {
      await txn.insert('investments', investment);
    }
  }
}
