import 'package:flutter/material.dart';
import '../databases/expense_category_dao.dart';
import '../databases/expense_dao.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../utils/app_scaffold.dart';
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
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  Map<int, String> _categoryMap = {};  // Map with int keys and String values

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
    List<Expense> expenses = await _expenseDao.getAllExpenses();
    List<ExpenseCategory> categories = await _expenseCategoryDao.getAllCategories();

    double totalCurrentMonthExpenses = 0.0;
    Map<String, double> monthlyTotals = {};

    DateTime now = DateTime.now();
    int currentMonth = now.month;
    int currentYear = now.year;

    for (var expense in expenses) {
      DateTime expenseDate = DateTime.parse(expense.dateSpent);
      String monthKey = '${expenseDate.year}-${expenseDate.month}';

      if (expenseDate.month == currentMonth && expenseDate.year == currentYear) {
        totalCurrentMonthExpenses += expense.amount;
      }

      if (monthlyTotals.containsKey(monthKey)) {
        monthlyTotals[monthKey] = monthlyTotals[monthKey]! + expense.amount;
      } else {
        monthlyTotals[monthKey] = expense.amount;
      }
    }

    setState(() {
      _expenses = expenses;
      _hasData = expenses.isNotEmpty;
      _visibleMonthTotal = totalCurrentMonthExpenses;
      _categoryMap = {for (var category in categories) category.id!: category.name};
    });
  }

  void _updateMonthLabel(int month, int year, List<Expense> expenses) {
    DateTime now = DateTime.now();

    if (month == now.month && year == now.year) {
    } else {
      DateFormat('MMMM').format(DateTime(year, month));
    }

    // Calculate total income for that month
    expenses.where((expense) {
      DateTime expenseDate = DateTime.parse(expense.dateSpent);
      return expenseDate.month == month && expenseDate.year == year;
    }).fold(0.0, (sum, income) => sum + income.amount);

    setState(() {
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
      title: 'Expenses',
      body: _hasData ? _buildExpenseContent() : NoDataScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditExpense(),
        child: Icon(Icons.add),
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
                  Text(
                    _currentMonth == DateTime.now().month && _currentYear == DateTime.now().year
                        ? 'Current Month'
                        : DateFormat('MMMM yyyy').format(DateTime(_currentYear, _currentMonth)),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '\$${_visibleMonthTotal.toStringAsFixed(2)}',
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
          SizedBox(height: 16),
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
            String categoryName = _categoryMap[expense.categoryId] ?? 'Unknown';

            return ListTile(
              title: Text(categoryName),
              subtitle: Text(expense.dateSpent),
              onTap: () => _addOrEditExpense(expense: expense),
              trailing: Text(
                '\$${expense.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            );
          }).toList(),
        ),
        Divider(),
      ],
    );
  }
}
