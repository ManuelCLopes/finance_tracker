import '../models/expense_category.dart';
import '../databases/database_helper.dart';

class ExpenseCategoryDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<ExpenseCategory>> getAllCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('expense_categories');

    return List.generate(maps.length, (i) {
      return ExpenseCategory.fromMap(maps[i]);
    });
  }

  Future<int> insertCategory(ExpenseCategory category) async {
    final db = await _dbHelper.database;
    return await db.insert('expense_categories', category.toMap());
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    final db = await _dbHelper.database;
    await db.update(
      'expense_categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(
        'expenses',
        where: 'category_id = ?',
        whereArgs: [id],
      );

      await txn.delete(
        'expense_categories',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<ExpenseCategory>> getExpenseCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('expense_categories');

    return List.generate(maps.length, (i) {
      return ExpenseCategory(
        id: maps[i]['id'],
        name: maps[i]['name'],
      );
    });
  }
}