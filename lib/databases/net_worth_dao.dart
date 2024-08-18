import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/net_worth.dart';

class NetWorthDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> insertNetWorth(NetWorth netWorth) async {
    final db = await _dbHelper.database;
    await db.insert('net_worth', netWorth.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<NetWorth>> getNetWorthByUserId(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'net_worth',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) {
      return NetWorth.fromMap(maps[i]);
    });
  }

  Future<void> updateNetWorth(NetWorth netWorth) async {
    final db = await _dbHelper.database;
    await db.update(
      'net_worth',
      netWorth.toMap(),
      where: 'id = ?',
      whereArgs: [netWorth.id],
    );
  }

  Future<void> deleteNetWorth(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'net_worth',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
