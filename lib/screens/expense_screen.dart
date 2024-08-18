import 'package:flutter/material.dart';
import '../databases/expense_dao.dart';
import '../models/expense.dart';
import '../utils/no_data.dart';
import 'expense_form.dart';
import 'package:intl/intl.dart';

import 'home_screen.dart';

class ExpenseScreen extends StatefulWidget {
  ExpenseScreen({Key? key}) : super(key: key);

  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();

  @override
  void refreshData() => _ExpenseScreenState()._loadData();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ExpenseDao _expenseDao = ExpenseDao();
  List<Expense> _expenses = [];
  bool _hasData = true;
  double _totalCurrentMonthExpenses = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void loadData() {
    _loadData(); // Public method to trigger data reload
  }

  Future<void> _loadData() async {
    List<Expense> expenses = await _expenseDao.getAllExpenses();
    double totalCurrentMonthExpenses = 0.0;

    DateTime now = DateTime.now();
    int currentMonth = now.month;
    int currentYear = now.year;

    for (var expense in expenses) {
      DateTime expenseDate = DateTime.parse(expense.dateSpent);

      if (expenseDate.month == currentMonth && expenseDate.year == currentYear) {
        totalCurrentMonthExpenses += expense.amount;
      }
    }
    print("Total Expenses for ${DateFormat('MMMM').format(now)}: $totalCurrentMonthExpenses");

    setState(() {
      _expenses = expenses;
      _hasData = expenses.isNotEmpty;
      _totalCurrentMonthExpenses = totalCurrentMonthExpenses;
    });
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses'),
      ),
      body: _hasData ? _buildExpenseContent() : NoDataScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditExpense(),
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildExpenseContent() {
    // Group expenses by date in descending order
    Map<String, List<Expense>> groupedExpenses = {};
    for (var expense in _expenses) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(expense.dateSpent));
      if (groupedExpenses.containsKey(formattedDate)) {
        groupedExpenses[formattedDate]!.add(expense);
      } else {
        groupedExpenses[formattedDate] = [expense];
      }
    }

    // Sort the dates in descending order
    List<String> sortedDates = groupedExpenses.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display total expenses for the current month in a card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Month',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '\$${_totalCurrentMonthExpenses.toStringAsFixed(2)}',
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
          // Build the list of expenses grouped by date
          Expanded(
            child: ListView.builder(
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
            return ListTile(
              title: Text(expense.category),
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
