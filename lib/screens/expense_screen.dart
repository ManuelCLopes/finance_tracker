import 'package:flutter/material.dart';
import '../databases/expense_category_dao.dart';
import '../databases/expense_dao.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../services/app_localizations_service.dart';
import '../utils/app_scaffold.dart';
import '../utils/currency_utils.dart';
import '../utils/no_data.dart';
import 'package:intl/intl.dart';

import 'expense_form.dart';

class ExpenseScreen extends StatefulWidget {
  ExpenseScreen({Key? key}) : super(key: key);

  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();

  void refreshData() => _ExpenseScreenState()._loadData();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ExpenseDao _expenseDao = ExpenseDao();
  final ExpenseCategoryDao _expenseCategoryDao = ExpenseCategoryDao();

  List<Expense> _expenses = [];
  bool _hasData = true;
  double _visibleMonthTotal = 0.0;
  String _currencySymbol = '\$'; // Default currency symbol
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  Map<int, String> _categoryMap = {};  // Map with int keys and String values
  Map<String, double> _monthlyTotals = {};

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScrollUpdate);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Fetch expenses and categories from the database
    List<Expense> expenses = await _expenseDao.getAllExpenses();
    List<ExpenseCategory> categories = await _expenseCategoryDao.getAllCategories();

    _monthlyTotals = {};

    // Load the currency symbol
    _currencySymbol = await CurrencyUtils.getCurrencySymbol();

    if (expenses.isNotEmpty) {
      // Sort expenses by date to find the last expense
      expenses.sort((a, b) => DateTime.parse(b.dateSpent).compareTo(DateTime.parse(a.dateSpent)));

      // Set the current month and year to the last expense's month and year
      DateTime lastExpenseDate = DateTime.parse(expenses.first.dateSpent);
      _currentMonth = lastExpenseDate.month;
      _currentYear = lastExpenseDate.year;
    } else {
      // If no expenses, default to current month and year
      DateTime now = DateTime.now();
      _currentMonth = now.month;
      _currentYear = now.year;
    }

    // Calculate monthly totals
    for (var expense in expenses) {
      DateTime expenseDate = DateTime.parse(expense.dateSpent);
      String monthKey = '${expenseDate.year}-${expenseDate.month}';

      if (_monthlyTotals.containsKey(monthKey)) {
        _monthlyTotals[monthKey] = _monthlyTotals[monthKey]! + expense.amount;
      } else {
        _monthlyTotals[monthKey] = expense.amount;
      }
    }

    // Set the visible month total to the total for the last expense's month
    String currentMonthKey = '$_currentYear-$_currentMonth';
    _visibleMonthTotal = _monthlyTotals[currentMonthKey] ?? 0.0;

    setState(() {
      _expenses = expenses;
      _hasData = expenses.isNotEmpty;
      _categoryMap = {for (var category in categories) category.id!: category.name};
    });
  }

  void _updateMonthLabel(int month, int year, List<Expense> expenses) {
    DateTime now = DateTime.now();

    if (month == now.month && year == now.year) {
      // Current month and year
    } else {
      DateFormat('MMMM').format(DateTime(year, month));
    }

    String monthKey = '$year-$month';
    _visibleMonthTotal = _monthlyTotals[monthKey] ?? 0.0;

    setState(() {
      _currentMonth = month;
      _currentYear = year;
      });
  }

  void _onScrollUpdate() {
    if (_scrollController.hasClients) {
      double itemHeight = 90.0; // Average height of each item
      int firstVisibleIndex = (_scrollController.offset / itemHeight).floor();

      if (firstVisibleIndex >= 0 && firstVisibleIndex < _expenses.length) {
        DateTime firstVisibleDate = DateTime.parse(_expenses[firstVisibleIndex].dateSpent);
        int visibleMonth = firstVisibleDate.month;
        int visibleYear = firstVisibleDate.year;

        if (visibleMonth != _currentMonth || visibleYear != _currentYear) {
          _currentMonth = visibleMonth;
          _currentYear = visibleYear;
          _updateMonthLabel(visibleMonth, visibleYear, _expenses);
        }
      }
    }
  }

  void _addOrEditExpense({Expense? expense}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseForm(expense: expense),
      ),
    );
    _loadData();
  }

  void _deleteExpense(String expenseId) async {
    await _expenseDao.deleteExpense(expenseId);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: AppLocalizations.of(context)!.translate('expenses'),
      body: _hasData ? _buildExpenseContent() : NoDataScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditExpense(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExpenseContent() {
    Map<String, List<Expense>> groupedExpenses = {};
    for (var expense in _expenses) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(expense.dateSpent));
      if (groupedExpenses.containsKey(formattedDate)) {
        groupedExpenses[formattedDate]!.add(expense);
      } else {
        groupedExpenses[formattedDate] = [expense];
      }
    }

    List<String> sortedDates = groupedExpenses.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Display the month and year of the last expense
                  Text(
                    DateFormat('MMMM yyyy').format(DateTime(_currentYear, _currentMonth)),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '${_visibleMonthTotal.toStringAsFixed(2)} $_currencySymbol',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                String date = sortedDates[index];
                List<Expense> expensesForDate = groupedExpenses[date]!;
                return _buildExpenseGroup(date, expensesForDate);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseGroup(String date, List<Expense> expenses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('MMMM dd, yyyy').format(DateTime.parse(date)),
          style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
        Column(
          children: expenses.map((expense) {
            String categoryName = _categoryMap[expense.categoryId] ?? AppLocalizations.of(context)?.translate('unknown') ?? 'Unknown';

            return ListTile(
              title: Text(categoryName),
              subtitle: Text(expense.dateSpent),
              onTap: () => _addOrEditExpense(expense: expense),
              trailing: Text(
                '${expense.amount.toStringAsFixed(2)} $_currencySymbol',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            );
          }).toList(),
        ),
        const Divider(),
      ],
    );
  }
}
