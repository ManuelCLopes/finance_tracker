import 'package:finance_tracker/models/expense_category.dart';
import 'package:finance_tracker/models/income_category.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart'; 
import 'package:workmanager/workmanager.dart';
import 'dart:convert';
import 'dart:io';

import '../databases/database_helper.dart';
import '../databases/expense_category_dao.dart';
import '../databases/expense_dao.dart';
import '../databases/income_category_dao.dart';
import '../databases/income_dao.dart';
import '../databases/investment_dao.dart';
import '../services/app_localizations_service.dart';

class BackupHelper {
  
  static Duration _getIntervalFromFrequency(BuildContext context, String frequency) {
    final localizations = AppLocalizations.of(context);

    // Fetch localized strings
    String daily = localizations?.translate('daily') ?? 'Daily';
    String weekly = localizations?.translate('weekly') ?? 'Weekly';
    String monthly = localizations?.translate('monthly') ?? 'Monthly';

    if (frequency == daily) {
      return const Duration(days: 1);
    } else if (frequency == weekly) {
      return const Duration(days: 7);
    } else if (frequency == monthly) {
      return const Duration(days: 30);
    } else {
      return const Duration(days: 7);
    }
  }

  // Schedule backup using WorkManager
  static Future<void> scheduleBackupTask({
    required BuildContext context,
    required String frequency,
  }) async {
    // perform an immediate backup to avoid waiting until the first scheduled time
    await exportToJson(scheduled: true);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('backup_frequency', frequency);

    // Cancel any existing scheduled backup
    await Workmanager().cancelAll();

    // Get backup interval based on user preference
    final Duration backupInterval = _getIntervalFromFrequency(context, frequency);

    // Register a periodic task with WorkManager
    await Workmanager().registerPeriodicTask(
      'backupTask',
      'backupTask',
      frequency: backupInterval,
      initialDelay: const Duration(minutes: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
        requiresCharging: false,
      ),
    );
  }

  // Method to be called by WorkManager to perform the backup
  static Future<void> scheduledBackup() async {
    await exportToJson(scheduled: true);
  }

  // Unschedule backup
  static Future<void> unscheduleBackup() async {
    await Workmanager().cancelAll(); // Cancel all scheduled tasks
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('backup_frequency'); // Clear the stored frequency
  }

  // Helper method to clear database
  Future<void> _clearDatabase(Database db) async {
    final tables = ['expenses', 'incomes', 'income_categories', 'expense_categories', 'investments'];
    for (String table in tables) {
      await db.delete(table);
    }
  }

  // Export backup to JSON
  static Future<String?> exportToJson({bool scheduled = false}) async {
    final data = await _getDataForBackup();
    Directory? directory;

    if (Platform.isAndroid) {
      if (await _requestStoragePermission()) {
        directory = Directory('/storage/emulated/0/Download'); // Use the Downloads folder
      } else {
        print('Storage permission not granted.');
        return null;
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (!await directory.exists()) {
      print('Could not determine a valid directory for saving the backup.');
      return null;
    }

    String filePath = scheduled ? '${directory.path}/scheduled_backup.json' : '${directory.path}/backup.json';
    final file = File(filePath);

    // Fetch database instance
    final Database db = await DatabaseHelper().database;

    // Convert each record to remove 'id', 'user_id', and replace 'category_id' with 'category_name'
    List<Map<String, dynamic>> sanitizedData = await Future.wait(data.map((record) async {
      Map<String, dynamic> sanitizedRecord = {};

      for (var entry in record.entries) {
        String key = entry.key;
        List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(entry.value);

        sanitizedRecord[key] = await Future.wait(items.map((item) async {
          Map<String, dynamic> sanitizedItem = Map.of(item);
          sanitizedItem.remove('id');
          sanitizedItem.remove('user_id');

          // Handle category ID to name conversion for expenses and incomes
          if (key == 'expenses' || key == 'incomes') {
            int categoryId = sanitizedItem['category_id'];
            String categoryName = await _getCategoryNameById(
                db,
                categoryId,
                key == 'expenses' ? 'expense_categories' : 'income_categories');
            sanitizedItem['category_name'] = categoryName;
            sanitizedItem.remove('category_id');
          }

          return sanitizedItem;
        }).toList());
      }

      return sanitizedRecord;
    }).toList());

    // Write the sanitized data to file
    await file.writeAsString(jsonEncode(sanitizedData));
    print('Backup saved at: $filePath'); // Debugging: Confirm file path
    return filePath;
  }

  // Helper method to request storage permissions on Android
  static Future<bool> _requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  // Helper to get category name by ID
  static Future<String> _getCategoryNameById(Database db, int? categoryId, String tableName) async {
    if (categoryId == null) {
      return '';  // Return an empty string if categoryId is null
    }

    var category = await db.query(tableName, where: 'id = ?', whereArgs: [categoryId]);
    return category.isNotEmpty ? category.first['name'].toString() : '';
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('confirm_import')),
          content: Text(AppLocalizations.of(context)!.translate('confirm_import_message')),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
              onPressed: () {
                Navigator.of(context).pop(false); // Return false if user cancels
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.translate('proceed')),
              onPressed: () {
                Navigator.of(context).pop(true); // Return true if user proceeds
              },
            ),
          ],
        );
      },
    ) ?? false; // Return false if dialog is dismissed without a decision
  }

  // Import backup from JSON using file picker
  Future<void> importFromJson(BuildContext context) async {
    try {
      bool proceed = await _showConfirmationDialog(context);
      if (!proceed) {
        return; // Exit if user cancels
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);

        if (await file.exists()) {
          final String fileContent = await file.readAsString();
          final jsonData = jsonDecode(fileContent);

          if (jsonData is List && jsonData.isNotEmpty) {
            var firstElement = jsonData.first;
            if (firstElement is Map<String, dynamic>) {
              final Database db = await DatabaseHelper().database;

              await _clearDatabase(db);

              final expenseCategoryDao = ExpenseCategoryDao();
              final incomeCategoryDao = IncomeCategoryDao();
              final expenseDao = ExpenseDao();
              final incomeDao = IncomeDao();
              final investmentDao = InvestmentDao();

              for (var item in firstElement['income_categories'] ?? []) {
                await _createOrUpdateCategory(incomeCategoryDao, db, item, 'income_categories');
              }

              for (var item in firstElement['expense_categories'] ?? []) {
                await _createOrUpdateCategory(expenseCategoryDao, db, item, 'expense_categories');
              }

              for (var item in firstElement['incomes'] ?? []) {
                await _createOrUpdateTransaction(incomeDao, db, item, 'incomes', 'income_categories');
              }

              for (var item in firstElement['expenses'] ?? []) {
                await _createOrUpdateTransaction(expenseDao, db, item, 'expenses', 'expense_categories');
              }

              for (var item in firstElement['investments'] ?? []) {
                await investmentDao.insertOrUpdateTransaction(item, db);
              }

            } else {
              print("First element is not a valid Map<String, dynamic>.");
            }
          } else {
            print("JSON data is not a list or is empty.");
          }
        } else {
          print('File does not exist.');
        }
      } else {
        print('No file selected or operation canceled.');
      }
    } catch (e) {
      print('Error during import: $e');
    }
  }

  // Helper to find or create a category
  static Future<void> _createOrUpdateCategory(dynamic dao, Database db, Map<String, dynamic> item, String tableName) async {
    String name = item['name'];
    var existing = await db.query(tableName, where: 'name = ?', whereArgs: [name]);

    if (existing.isNotEmpty) {
      item['id'] = existing.first['id'];
    } else {
      if (dao is ExpenseCategoryDao) {
        ExpenseCategory category = ExpenseCategory(name: item['name']);
        item['id'] = await dao.insertCategory(category);
      } else if (dao is IncomeCategoryDao) {
        IncomeCategory category = IncomeCategory(name: item['name']);
        item['id'] = await dao.insertCategory(category);
      } else {
        print('Error: DAO is not of the correct type for category insertion.');
      }
    }
  }

  // Helper to find or create a transaction
  static Future<void> _createOrUpdateTransaction(dynamic dao, Database db, Map<String, dynamic> item, String tableName, String categoryTable) async {
    Object? categoryName = await _getCategoryNameById(db, item['category_id'], categoryTable);
    if (categoryName == '') {
      categoryName = item['category_name'];
    }

    var category = await db.query(categoryTable, where: 'name = ?', whereArgs: [categoryName]);

    if (category.isNotEmpty) {
      item['category_id'] = category.first['id'];
    } else {
      int newCategoryId = await dao.insertCategory({'name': categoryName}, db);
      item['category_id'] = newCategoryId;
    }
    item.remove('category_name');

    await dao.insertOrUpdateTransaction(item, db);
  }

  static Future<int> _getOrCreateCategoryIdByName(
    Database db,
    String categoryName,
    String tableName,
    dynamic categoryDao,
  ) async {
    var category = await db.query(tableName, where: 'name = ?', whereArgs: [categoryName]);

    if (category.isNotEmpty) {
      return category.first['id'] as int;
    } else {
      return await categoryDao.insertCategory({'name': categoryName}, db);
    }
  }

  // Helper methods for data backup and restoration
  static Future<List<Map<String, dynamic>>> _getDataForBackup() async {
    final db = await DatabaseHelper().database;

    final incomeCategories = await db.query('income_categories');
    final expenseCategories = await db.query('expense_categories');
    final incomes = await db.query('incomes');
    final expenses = await db.query('expenses');
    final investments = await db.query('investments');

    return [
      {
        'income_categories': incomeCategories,
        'expense_categories': expenseCategories,
        'incomes': incomes,
        'expenses': expenses,
        'investments': investments,
      }
    ];
  }
}
