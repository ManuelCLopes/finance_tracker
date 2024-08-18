import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/savings.dart';

class SavingsDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> insertSavings(Savings savings) async {
    final db = await _dbHelper.database;
    await db.insert('savings', savings.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Savings>> getSavingsByUserId(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'savings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) {
      return Savings.fromMap(maps[i]);
    });
  }

  Future<void> updateSavings(Savings savings) async {
    final db = await _dbHelper.database;
    await db.update(
      'savings',
      savings.toMap(),
      where: 'id = ?',
      whereArgs: [savings.id],
    );
  }

  Future<void> deleteSavings(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'savings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
