import 'package:finance_tracker/screens/expense_form.dart';
import 'package:finance_tracker/screens/income_form.dart';
import 'package:finance_tracker/screens/investment_form.dart';
import 'package:flutter/material.dart';
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
import '../utils/app_scaffold.dart';
import '../utils/currency_utils.dart';
import '../utils/theme_pie_chart.dart';

class OverviewScreen extends StatefulWidget {
  final Key? key;
  const OverviewScreen({this.key}) : super(key: key);

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
  String _currencySymbol = '\$'; // Default currency symbol

  List<dynamic> _lastTransactions = [];

  Map<int, String> _expenseCategoryMap = {};
  Map<int, String> _incomeCategoryMap = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData(); 
  }

  void loadData() => _OverviewScreenState()._loadData();

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Load categories
    List<ExpenseCategory> expenseCategories = await _expenseCategoryDao.getAllCategories();
    List<IncomeCategory> incomeCategories = await _incomeCategoryDao.getAllCategories();

    // Map category IDs to their names
    _expenseCategoryMap = {for (var category in expenseCategories) category.id!: category.name};
    _incomeCategoryMap = {for (var category in incomeCategories) category.id!: category.name};

    // Load transactions (consider fetching only the recent 10 transactions at the database level)
    List<Income> incomes = await _incomeDao.getAllIncomes();
    List<Expense> expenses = await _expenseDao.getAllExpenses();
    List<Investment> investments = await _investmentDao.getAllInvestments();

    // Load the currency symbol
    _currencySymbol = await CurrencyUtils.getCurrencySymbol();

    double totalIncome = incomes.fold(0.0, (sum, income) => sum + income.amount);
    double totalExpenses = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    double totalInvestments = investments.fold(0.0, (sum, investment) => sum + investment.currentValue);
    double netWorth = totalIncome - totalExpenses + totalInvestments;

    // Combine, sort, and then take only the last 10 transactions
    List<dynamic> transactions = [
      ...expenses,
      ...incomes,
      ...investments,
    ]..sort((a, b) {
        DateTime dateA, dateB;
        if (a is Expense) {
          dateA = DateTime.parse(a.dateSpent);
        } else if (a is Income) {
          dateA = DateTime.parse(a.dateReceived);
        } else {
          dateA = DateTime.parse((a as Investment).dateInvested);
        }

        if (b is Expense) {
          dateB = DateTime.parse(b.dateSpent);
        } else if (b is Income) {
          dateB = DateTime.parse(b.dateReceived);
        } else {
          dateB = DateTime.parse((b as Investment).dateInvested);
        }
        return dateB.compareTo(dateA); // Sort by most recent first
      });

    // Limit the transactions to the last 10
    _lastTransactions = transactions.take(10).toList();

    setState(() {
      _totalIncome = totalIncome;
      _totalExpenses = totalExpenses;
      _totalInvestments = totalInvestments;
      _netWorth = netWorth;
      _hasData = incomes.isNotEmpty || expenses.isNotEmpty || investments.isNotEmpty;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Overview',
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
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
          if (_totalIncome > 0 || _totalExpenses > 0) const SizedBox(height: 16),
          _buildNetWorthSummary(),
          const SizedBox(height: 8),
          _buildInvestmentSummary(),
          const SizedBox(height: 32),
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
          const SizedBox(height: 48),
          SvgPicture.asset(
            'assets/images/savings.svg',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 60),
          _buildNoDataButton('Add First Income', IncomeForm()),
          const SizedBox(height: 16),
          _buildNoDataButton('Add First Expense', const ExpenseForm()),
          const SizedBox(height: 16),
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
      child: Text(text),
    );
  }

  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _showAddOptions(context);
      },
      child: const Icon(Icons.add),
    );
  }

  Widget _buildIncomeVsExpensesSummary() {
    return ThemedPieChart(
      incomeValue: _totalIncome,
      expenseValue: _totalExpenses,
      investedValue: _totalInvestments,
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
              '${_netWorth.toStringAsFixed(2)} $_currencySymbol',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 123, 122, 122),
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
              '${_totalInvestments.toStringAsFixed(2)} $_currencySymbol',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 123, 122, 122),
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
        const SizedBox(height: 16),
        _buildTransactionList(),
      ],
    );
  }

  Widget _buildTransactionList() {
    final ThemeData theme = Theme.of(context);
    final Color incomeColor = theme.brightness == Brightness.light
        ? const Color(0xFF004B3A) 
        : const Color(0xFFA5C8AA);
    final Color expenseColor = theme.brightness == Brightness.light
        ? const Color(0xFFB00020)
        : const Color(0xFFD6726D);
    final Color investmentColor = theme.brightness == Brightness.light
        ? const Color.fromARGB(255, 172, 141, 40) 
        : const Color(0xFFC8B07D);

    return Column(
      children: _lastTransactions.map((transaction) {
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
          amountColor = expenseColor;
          icon = Icons.arrow_upward;
          destinationScreen = ExpenseForm(expense: transaction);
        } else if (transaction is Income) {
          category = _incomeCategoryMap[transaction.categoryId] ?? 'Unknown';
          date = transaction.dateReceived;
          amount = transaction.amount;
          amountColor = incomeColor;
          icon = Icons.arrow_downward;
          destinationScreen = IncomeForm(income: transaction);
        } else if (transaction is Investment) {
          category = transaction.investmentType;
          date = transaction.dateInvested;
          amount = transaction.initialValue;
          amountColor = investmentColor;
          icon = Icons.show_chart;
          destinationScreen = InvestmentForm(investment: transaction);
        }

        return ListTile(
          leading: Icon(icon, color: amountColor),
          title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(date),
          trailing: Text(
            '${amount.toStringAsFixed(2)} $_currencySymbol',
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
            _buildAddOption('Add Expense', Icons.shopping_cart, const ExpenseForm()),
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
