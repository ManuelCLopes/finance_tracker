import '../models/income_category.dart';
import '../databases/database_helper.dart';

class IncomeCategoryDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<IncomeCategory>> getAllCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('income_categories');

    return List.generate(maps.length, (i) {
      return IncomeCategory.fromMap(maps[i]);
    });
  }

  Future<int> insertCategory(IncomeCategory category) async {
    final db = await _dbHelper.database;
    return await db.insert('income_categories', category.toMap());
  }

  Future<void> updateCategory(IncomeCategory category) async {
    final db = await _dbHelper.database;
    await db.update(
      'income_categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'income_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

}
