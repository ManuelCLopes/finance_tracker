import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'dart:io';

import '../databases/database_helper.dart';
import '../databases/expense_category_dao.dart';
import '../databases/expense_dao.dart';
import '../databases/income_category_dao.dart';
import '../databases/income_dao.dart';
import '../databases/investment_dao.dart';

class BackupHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notification plugin
  static Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  // Schedule backup
  static Future<void> scheduleBackup({required String frequency}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('backup_frequency', frequency);

    _getIntervalFromFrequency(frequency);

    await _notificationsPlugin.periodicallyShow(
      0,
      'Scheduled Backup',
      'Your data is being backed up.',
      RepeatInterval.everyMinute, // For testing; change to a suitable interval
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'backup_channel',
          'Scheduled Backup',
          channelDescription: 'Notification for scheduled backup',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      androidAllowWhileIdle: true,
    );

    // Perform an immediate backup to avoid waiting until the first scheduled time
    await BackupHelper.exportToJson(); // or exportToCsv() based on user preference
  }

  static Future<void> scheduledBackup() async {
    final directory = await getApplicationDocumentsDirectory();
    String filePath = '${directory.path}/scheduled_backup.json';

    final data = await _getDataForBackup();

    final file = File(filePath);
    await file.writeAsString(jsonEncode(data));

    print('Scheduled backup saved at $filePath');
  }

  // Unschedule backup
  static Future<void> unscheduleBackup() async {
    await _notificationsPlugin.cancel(0);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('backup_frequency');
  }

  // Export backup to JSON
  static Future<String?> exportToJson() async {
    final data = await _getDataForBackup();
    final directory = await getApplicationDocumentsDirectory();
    String filePath = '${directory.path}/backup.json';
    final file = File(filePath);
    await file.writeAsString(jsonEncode(data));
    return filePath;
  }

  // Export backup to CSV
  static Future<String?> exportToCsv() async {
    final data = await _getDataForBackup();
    final csvData = _convertToCsv(data);
    final directory = await getApplicationDocumentsDirectory();
    String filePath = '${directory.path}/backup.csv';
    final file = File(filePath);
    await file.writeAsString(csvData);
    return filePath;
  }

  // Import backup from JSON
  static Future<void> importFromJson() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/backup.json');

    if (await file.exists()) {
      final jsonData = jsonDecode(await file.readAsString());
      if (jsonData is List) {
        await restoreDataFromBackup(jsonData.first);
      }
    }
  }

  // Import backup from CSV
  static Future<void> importFromCsv() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/backup.csv');

    if (await file.exists()) {
      final csvData = await file.readAsString();
      final jsonData = _convertFromCsv(csvData);
      await restoreDataFromBackup(jsonData);
    }
  }

  // Restore data from backup including categories
  static Future<void> restoreDataFromBackup(Map<String, List<Map<String, dynamic>>> data) async {
    final Database db = await DatabaseHelper().database;

    await db.transaction((txn) async {
      final expenseCategoryDao = ExpenseCategoryDao();
      final incomeCategoryDao = IncomeCategoryDao();
      final expenseDao = ExpenseDao();
      final incomeDao = IncomeDao();
      final investmentDao = InvestmentDao();

      await expenseCategoryDao.bulkInsertCategories(data['expense_categories'] ?? [], txn);
      await incomeCategoryDao.bulkInsertCategories(data['income_categories'] ?? [], txn);
      await expenseDao.bulkInsertExpenses(data['expenses'] ?? [], txn);
      await incomeDao.bulkInsertIncomes(data['incomes'] ?? [], txn);
      await investmentDao.bulkInsertInvestments(data['investments'] ?? [], txn);
    });
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

  static String _convertToCsv(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';

    final headers = data.first.keys.join(',');
    final rows = data.map((row) {
      return row.values.join(',');
    }).join('\n');

    return '$headers\n$rows';
  }

  static Map<String, List<Map<String, dynamic>>> _convertFromCsv(String csvData) {
    final lines = csvData.split('\n');
    final headers = lines.first.split(',');

    return {
      'data': lines.skip(1).map((line) {
        final values = line.split(',');
        return Map<String, dynamic>.fromIterables(headers, values);
      }).toList(),
    };
  }

  static int _getIntervalFromFrequency(String frequency) {
    switch (frequency) {
      case 'daily':
        return 1;
      case 'weekly':
        return 7;
      case 'monthly':
        return 30;
      default:
        return 7;
    }
  }
}