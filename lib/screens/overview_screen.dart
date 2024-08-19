import 'package:finance_tracker/screens/expense_form.dart';
import 'package:finance_tracker/screens/income_form.dart';
import 'package:finance_tracker/screens/investment_form.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../databases/expense_category_dao.dart';
import '../databases/expense_dao.dart';
import '../databases/income_category_dao.dart';
import '../databases/income_dao.dart';
import '../databases/investment_dao.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/investment.dart';
import '../models/expense_category.dart';
import '../models/income_category.dart';
import '../utils/app_drawer.dart';
import '../utils/app_scaffold.dart';

class OverviewScreen extends StatefulWidget {
  final Key? key;
  OverviewScreen({this.key}) : super(key: key);

  @override
  _OverviewScreenState createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final ExpenseDao _expenseDao = ExpenseDao();
  final IncomeDao _incomeDao = IncomeDao();
  final InvestmentDao _investmentDao = InvestmentDao();
  final ExpenseCategoryDao _expenseCategoryDao = ExpenseCategoryDao();
  final IncomeCategoryDao _incomeCategoryDao = IncomeCategoryDao();


  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _totalInvestments = 0.0;
  double _netWorth = 0.0;
  bool _hasData = true;
  bool _isLoading = true;
  List<dynamic> _lastFiveTransactions = [];

  Map<int, String> _expenseCategoryMap = {};
  Map<int, String> _incomeCategoryMap = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData(); // Refresh data whenever dependencies change
  }

  void loadData() => _OverviewScreenState()._loadData();

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true; // Show loading indicator during data fetch
    });

    // Load categories
    List<ExpenseCategory> expenseCategories = await _expenseCategoryDao.getAllCategories();
    List<IncomeCategory> incomeCategories = await _incomeCategoryDao.getAllCategories();

    // Map category IDs to their names
    _expenseCategoryMap = {for (var category in expenseCategories) category.id!: category.name};
    _incomeCategoryMap = {for (var category in incomeCategories) category.id!: category.name};

    // Load transactions
    List<Income> incomes = await _incomeDao.getAllIncomes();
    List<Expense> expenses = await _expenseDao.getAllExpenses();
    List<Investment> investments = await _investmentDao.getAllInvestments();

    double totalIncome = incomes.fold(0.0, (sum, income) => sum + income.amount);
    double totalExpenses = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    double totalInvestments = investments.fold(0.0, (sum, investment) => sum + investment.currentValue);

    double netWorth = totalIncome - totalExpenses + totalInvestments;

    setState(() {
      _totalIncome = totalIncome;
      _totalExpenses = totalExpenses;
      _totalInvestments = totalInvestments;
      _netWorth = netWorth;
      _hasData = incomes.isNotEmpty || expenses.isNotEmpty || investments.isNotEmpty;
      _lastFiveTransactions = [
        ...expenses.take(5),
        ...incomes.take(5),
        ...investments.take(5)
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Overview',
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : _hasData ? _buildDataContent() : _buildNoDataContent(),
      floatingActionButton: _hasData ? _buildFloatingActionButton() : null,
    );
  }

  Widget _buildDataContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_totalIncome > 0 || _totalExpenses > 0) _buildIncomeVsExpensesSummary(),
          if (_totalIncome > 0 || _totalExpenses > 0) SizedBox(height: 16),
          _buildNetWorthSummary(),
          SizedBox(height: 8),
          _buildInvestmentSummary(),
          SizedBox(height: 32),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildNoDataContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'You seem new here! \nStart tracking your money',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 48),
          SvgPicture.asset(
            'assets/images/savings.svg',
            width: 150,
            height: 150,
          ),
          SizedBox(height: 60),
          _buildNoDataButton('Add First Income', IncomeForm()),
          SizedBox(height: 16),
          _buildNoDataButton('Add First Expense', ExpenseForm()),
          SizedBox(height: 16),
          _buildNoDataButton('Add First Investment', InvestmentForm()),
        ],
      ),
    );
  }

  ElevatedButton _buildNoDataButton(String text, Widget form) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => form),
        );
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Theme.of(context).dialogBackgroundColor,
      ),
      child: Text(text),
    );
  }

  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _showAddOptions(context);
      },
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      child: Icon(Icons.add),
    );
  }

  Widget _buildIncomeVsExpensesSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estimated Net Worth',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 16),
        _buildPieChart(),
        SizedBox(height: 16),
        _buildPieChartLabels(),
      ],
    );
  }

  Widget _buildPieChart() {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            _buildPieChartSection(_totalIncome, Color(0xFF004B3A)),
            _buildPieChartSection(_totalExpenses, Color(0xFF800020)),
            _buildPieChartSection(_totalInvestments, Color(0xFFB8860B)),
          ],
          centerSpaceRadius: 30,
        ),
      ),
    );
  }

  PieChartSectionData _buildPieChartSection(double value, Color color) {
    return PieChartSectionData(
      color: color,
      value: value,
      radius: 60,
      title: '',
    );
  }

  Widget _buildPieChartLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPieChartLabel('Income', Color(0xFF004B3A)),
        _buildPieChartLabel('Expenses', Color(0xFF800020)),
        _buildPieChartLabel('Invested', Color(0xFFB8860B)),
      ],
    );
  }

  Widget _buildPieChartLabel(String text, Color color) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        SizedBox(height: 4),
        Text(text),
      ],
    );
  }

  Widget _buildNetWorthSummary() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current Net Worth',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '\$${_netWorth.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentSummary() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Investments',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '\$${_totalInvestments.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB8860B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 16),
        _buildTransactionList(),
      ],
    );
  }

  Widget _buildTransactionList() {
    return Column(
      children: _lastFiveTransactions.map((transaction) {
        String category = '';
        String date = '';
        double amount = 0.0;
        Color amountColor = Colors.black;
        IconData icon = Icons.monetization_on;
        Widget? destinationScreen;

        if (transaction is Expense) {
          category = _expenseCategoryMap[transaction.categoryId] ?? 'Unknown';
          date = transaction.dateSpent;
          amount = transaction.amount;
          amountColor = Color(0xFF800020);
          icon = Icons.arrow_upward;
          destinationScreen = ExpenseForm(expense: transaction);
        } else if (transaction is Income) {
          category = _incomeCategoryMap[transaction.categoryId] ?? 'Unknown';
          date = transaction.dateReceived;
          amount = transaction.amount;
          amountColor = Color(0xFF004B3A);
          icon = Icons.arrow_downward;
          destinationScreen = IncomeForm(income: transaction);
        } else if (transaction is Investment) {
          category = transaction.investmentType;
          date = transaction.dateInvested;
          amount = transaction.initialValue; // Use initial value for investments
          amountColor = Color(0xFFB8860B);
          icon = Icons.show_chart;
          destinationScreen = InvestmentForm(investment: transaction);
        }

        return ListTile(
          leading: Icon(icon, color: amountColor),
          title: Text(category, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(date),
          trailing: Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(color: amountColor, fontSize: 14),
          ),
          onTap: destinationScreen != null
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => destinationScreen!),
                  );
                }
              : null,
        );
      }).toList(),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            _buildAddOption('Add Income', Icons.attach_money, IncomeForm()),
            _buildAddOption('Add Expense', Icons.shopping_cart, ExpenseForm()),
            _buildAddOption('Add Investment', Icons.show_chart, InvestmentForm()),
          ],
        );
      },
    );
  }

  ListTile _buildAddOption(String text, IconData icon, Widget form) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => form),
        );
      },
    );
  }
}
