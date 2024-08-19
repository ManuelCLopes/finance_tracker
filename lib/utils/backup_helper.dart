import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:sqflite/sqflite.dart';

import '../databases/database_helper.dart';

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
    final data = await _getDataForBackup();
    final csvData = _convertToCsv(data);
    final directory = await getApplicationDocumentsDirectory();
    String filePath = '${directory.path}/backup.csv';
    final file = File(filePath);
    await file.writeAsString(csvData);
    return filePath;
  }

  static Future<void> importFromJson() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/backup.json');

    if (await file.exists()) {
        final dynamic jsonData = jsonDecode(await file.readAsString());

        // Ensure the decoded JSON data is a List<Map<String, dynamic>>
        if (jsonData is List) {
            final List<Map<String, dynamic>> data = jsonData.cast<Map<String, dynamic>>();

            await restoreDataFromBackup(data);
        } else {
            throw Exception("Invalid JSON format: Expected a List of Maps.");
        }
    }
}

  // Convert CSV data to List<Map<String, dynamic>>
  static List<Map<String, dynamic>> _convertFromCsv(String csvData) {
    final lines = const CsvToListConverter().convert(csvData);
    final headers = List<String>.from(lines.first);

    return lines.skip(1).map((line) {
      final values = List<String>.from(line.map((value) => value.toString()));

      // Ensure the values length matches headers length by adding nulls if needed
      if (values.length < headers.length) {
        values.addAll(List<String>.filled(headers.length - values.length, ''));
      }

      // If there are more values than headers, truncate the list
      final truncatedValues = values.take(headers.length).toList();

      return Map<String, dynamic>.fromIterables(headers, truncatedValues);
    }).toList();
  }

  // Import from CSV
  static Future<void> importFromCsv() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/backup.csv');

    if (await file.exists()) {
      final csvData = await file.readAsString();
      final jsonData = _convertFromCsv(csvData);
      await restoreDataFromBackup(jsonData);
    }
  }

  static Future<void> restoreDataFromBackup(List<Map<String, dynamic>> data) async {
    final Database db = await DatabaseHelper().database;

    await db.transaction((txn) async {
      for (var entry in data) {
        switch (entry['type']) {
          case 'income_categories':
            await DatabaseHelper().bulkInsert('income_categories', entry['data'], txn);
            break;
          case 'expense_categories':
            await DatabaseHelper().bulkInsert('expense_categories', entry['data'], txn);
            break;
          case 'incomes':
            await DatabaseHelper().bulkInsert('incomes', entry['data'], txn);
            break;
          case 'expenses':
            await DatabaseHelper().bulkInsert('expenses', entry['data'], txn);
            break;
          case 'investments':
            await DatabaseHelper().bulkInsert('investments', entry['data'], txn);
            break;
        }
      }
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
