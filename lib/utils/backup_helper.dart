import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:sqflite/sqflite.dart';

import '../databases/database_helper.dart';
import '../databases/expense_category_dao.dart';
import '../databases/expense_dao.dart';
import '../databases/income_category_dao.dart';
import '../databases/income_dao.dart';
import '../databases/investment_dao.dart';

class BackupHelper {
  static Future<void> backupData(BuildContext context, {required bool isCsv}) async {
    final directory = await getApplicationDocumentsDirectory();
    final filename = isCsv ? 'backup.csv' : 'backup.json';
    final path = '${directory.path}/$filename';

    // Substitua por sua lógica de obtenção de dados
    final data = await _getDataForBackup();

    String content;
    if (isCsv) {
      content = _generateCsv(data);
    } else {
      content = jsonEncode(data);
    }

    final file = File(path);
    await file.writeAsString(content);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backup saved in $path')),
    );
  }

  static Future<List<Map<String, dynamic>>> _getIncomes(Database db) async {
    return await db.query('incomes');
  }

  static Future<List<Map<String, dynamic>>> _getExpenses(Database db) async {
    return await db.query('expenses');
  }

  static Future<List<Map<String, dynamic>>> _getInvestments(Database db) async {
    return await db.query('investments');
  }

  static Future<List<Map<String, dynamic>>> _getIncomeCategories(Database db) async {
    return await db.query('income_categories');
  }

  static Future<List<Map<String, dynamic>>> _getExpenseCategories(Database db) async {
    return await db.query('expense_categories');
  }

  static Future<List<Map<String, dynamic>>> _getDataForBackup() async {
    final db = await DatabaseHelper().database;

    final incomeCategories = await _getIncomeCategories(db);
    final expenseCategories = await _getExpenseCategories(db);
    final incomes = await _getIncomes(db);
    final expenses = await _getExpenses(db);
    final investments = await _getInvestments(db);

    final backupData = {
      'income_categories': incomeCategories,
      'expense_categories': expenseCategories,
      'incomes': incomes,
      'expenses': expenses,
      'investments': investments,
    };

    return [backupData];
  }

  static String _generateCsv(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';

    final headers = data.first.keys.toList();
    final rows = data.map((row) => headers.map((key) => row[key].toString()).toList()).toList();

    return ListToCsvConverter().convert([headers, ...rows]);
  }

  static Future<String?> exportToJson() async {
    final data = await _getDataForBackup();
    final directory = await getApplicationDocumentsDirectory();
    String filePath = '${directory.path}/backup.json';
    final file = File(filePath);
    await file.writeAsString(jsonEncode(data));
    return filePath;
  }

  static Future<String?> exportToCsv() async {
    final db = await DatabaseHelper().database;

    final incomeCategories = await _getIncomeCategories(db);
    final expenseCategories = await _getExpenseCategories(db);
    final incomes = await _getIncomes(db);
    final expenses = await _getExpenses(db);
    final investments = await _getInvestments(db);

    List<List<dynamic>> csvData = [];

    // Add headers
    csvData.add(['Table', 'ID', 'Data']);

    // Add data for each table
    csvData.addAll(_flattenData('income_categories', incomeCategories));
    csvData.addAll(_flattenData('expense_categories', expenseCategories));
    csvData.addAll(_flattenData('incomes', incomes));
    csvData.addAll(_flattenData('expenses', expenses));
    csvData.addAll(_flattenData('investments', investments));

    final directory = await getApplicationDocumentsDirectory();
    String filePath = '${directory.path}/backup.csv';
    final file = File(filePath);

    String csv = const ListToCsvConverter().convert(csvData);
    await file.writeAsString(csv);

    return filePath;
  }

  static List<List<dynamic>> _flattenData(String tableName, List<Map<String, dynamic>> data) {
    return data.map((row) {
      return [tableName, row['id'], jsonEncode(row)];
    }).toList();
  }


  static Future<void> importFromJson() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/backup.json');

    if (await file.exists()) {
      final jsonData = jsonDecode(await file.readAsString());

      // Debugging: Print the structure of jsonData
      print("Imported JSON structure: ${jsonData.runtimeType}");
      print(jsonData);

      if (jsonData is List) {
        for (var item in jsonData) {
          if (item is Map<String, dynamic>) {
            await restoreDataFromBackup(item);
          } else {
            throw Exception('Invalid item in JSON list: Expected Map<String, dynamic>');
          }
        }
      } else {
        throw Exception('Invalid JSON structure: Expected List<Map<String, dynamic>>');
      }
    }
  }

  static List<Map<String, dynamic>> _convertFromCsv(String csvData) {
    final lines = csvData.split('\n');

    // Ensure that there are lines to process
    if (lines.isEmpty) {
      return [];
    }

    // The first line is assumed to be the headers
    final headers = lines.first.split(',');

    return lines.skip(1).where((line) => line.trim().isNotEmpty).map((line) {
      final values = line.split(',');

      // Truncate or extend the values list to match the headers length
      final truncatedValues = values.length > headers.length 
          ? values.sublist(0, headers.length) 
          : values + List.filled(headers.length - values.length, '');

      print('Headers: $headers');
      print('Values: $truncatedValues');

      // Ensure headers and values have the same length
      if (truncatedValues.length == headers.length) {
        return Map<String, dynamic>.fromIterables(headers, truncatedValues);
      } else {
        // Handle mismatches (optional: log or handle errors)
        print('Mismatch between headers and values lengths');
        return <String, dynamic>{}; // Or throw an error or handle as needed
      }
    }).toList();
  }


  static Future<void> importFromCsv() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/backup.csv');

    if (await file.exists()) {
      final csvData = await file.readAsString();
      final List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);

      final Map<String, List<Map<String, dynamic>>> groupedData = {};

      for (var row in rows.skip(1)) { // Skip headers
        final tableName = row[0] as String;
        final jsonData = jsonDecode(row[2] as String) as Map<String, dynamic>;

        // Group data by table name
        if (!groupedData.containsKey(tableName)) {
          groupedData[tableName] = [];
        }
        groupedData[tableName]!.add(jsonData);
      }

      // Now restore the data using the grouped data
      await restoreDataFromBackup(groupedData);
    }
  }



  static Future<void> restoreDataFromBackup(Map<String, dynamic> data) async {
  final Database db = await DatabaseHelper().database;

  await db.transaction((txn) async {
    // Ensure each data entry is a List<Map<String, dynamic>>
    data.forEach((key, value) async {
      if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
        // Process income categories
        if (key == 'income_categories') {
          final incomeCategoryDao = IncomeCategoryDao();
          await incomeCategoryDao.bulkInsertCategories(List<Map<String, dynamic>>.from(value), txn);
        }
        // Process expense categories
        else if (key == 'expense_categories') {
          final expenseCategoryDao = ExpenseCategoryDao();
          await expenseCategoryDao.bulkInsertCategories(List<Map<String, dynamic>>.from(value), txn);
        }
        // Process incomes
        else if (key == 'incomes') {
          final incomeDao = IncomeDao();
          await incomeDao.bulkInsertIncomes(List<Map<String, dynamic>>.from(value), txn);
        }
        // Process expenses
        else if (key == 'expenses') {
          final expenseDao = ExpenseDao();
          await expenseDao.bulkInsertExpenses(List<Map<String, dynamic>>.from(value), txn);
        }
        // Process investments
        else if (key == 'investments') {
          final investmentDao = InvestmentDao();
          await investmentDao.bulkInsertInvestments(List<Map<String, dynamic>>.from(value), txn);
        }
      } else {
        throw Exception('Unexpected structure for key "$key": Expected List<Map<String, dynamic>>');
      }
    });
  });
}

  static String _convertToCsv(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';

    final headers = data.first.keys.join(',');
    final rows = data.map((row) {
      return row.values.join(',');
    }).join('\n');

    return '$headers\n$rows';
  }

  // Schedule Backup (Placeholder - Should be implemented with proper scheduling)
  static void scheduleBackup(String frequency) {
    // Placeholder for scheduling logic
  }

  // Unschedule Backup (Placeholder - Should be implemented with proper scheduling)
  static void unscheduleBackup() {
    // Placeholder for unscheduling logic
  }

}
