import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:finance_tracker/screens/expense_form.dart';
import 'package:finance_tracker/screens/income_form.dart';
import 'package:finance_tracker/screens/investment_form.dart';
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
import '../services/app_localizations_service.dart';
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

    double totalIncome = incomes.fold(0.0, (sum, income) => sum + income.amount - income.taxAmount);
    double totalExpenses = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    double totalInvestments = investments.fold(0.0, (sum, investment) => sum + (investment.currentValue ?? 0.0));
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
    final localizations = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final bool isLightMode = theme.brightness == Brightness.light;

    // Choose the appropriate SVG file based on the theme
    final String assetName = isLightMode
        ? 'assets/images/savings_light.svg'
        : 'assets/images/savings_dark.svg';

    return AppScaffold(
      title: localizations?.translate('overview_title') ?? 'Overview',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasData ? _buildDataContent(localizations!) : _buildNoDataContent(assetName, localizations!),
      floatingActionButton: _hasData ? _buildFloatingActionButton(localizations!) : null,
    );
  }

  Widget _buildDataContent(AppLocalizations localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_totalIncome > 0 || _totalExpenses > 0 || _totalInvestments > 0) _buildIncomeVsExpensesSummary(localizations),
          if (_totalIncome > 0 || _totalExpenses > 0 || _totalInvestments > 0) const SizedBox(height: 16),
          _buildNetWorthSummary(localizations),
          const SizedBox(height: 8),
          _buildInvestmentSummary(localizations),
          const SizedBox(height: 32),
          _buildRecentTransactions(localizations),
        ],
      ),
    );
  }

  Widget _buildNoDataContent(String assetName, AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              localizations.translate('no_data_message'),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),
          SvgPicture.asset(
            assetName,
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 60),
          _buildNoDataButton(localizations.translate('add_first_income'), IncomeForm()),
          const SizedBox(height: 16),
          _buildNoDataButton(localizations.translate('add_first_expense'), const ExpenseForm()),
          const SizedBox(height: 16),
          _buildNoDataButton(localizations.translate('add_first_investment'), InvestmentForm()),
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

  FloatingActionButton _buildFloatingActionButton(AppLocalizations localizations) {
    return FloatingActionButton(
      onPressed: () {
        _showAddOptions(context, localizations);
      },
      child: const Icon(Icons.add),
    );
  }

  Widget _buildIncomeVsExpensesSummary(AppLocalizations localizations) {
    return ThemedPieChart(
      incomeValue: _totalIncome,
      expenseValue: _totalExpenses,
      investedValue: _totalInvestments, 
      currencySymbol: _currencySymbol,
    );
  }

  Widget _buildNetWorthSummary(AppLocalizations localizations) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localizations.translate('current_net_worth'),
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

  Widget _buildInvestmentSummary(AppLocalizations localizations) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localizations.translate('total_investments'),
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

  Widget _buildRecentTransactions(AppLocalizations localizations) {
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
          category = _expenseCategoryMap[transaction.categoryId] ?? localizations.translate('unknown_category');
          date = transaction.dateSpent;
          amount = transaction.amount;
          amountColor = expenseColor;
          icon = Icons.arrow_upward;
          destinationScreen = ExpenseForm(expense: transaction);
        } else if (transaction is Income) {
          category = _incomeCategoryMap[transaction.categoryId] ?? localizations.translate('unknown');
          date = transaction.dateReceived;
          amount = transaction.amount;
          amountColor = incomeColor;
          icon = Icons.arrow_downward;
          destinationScreen = IncomeForm(income: transaction);
        } else if (transaction is Investment) {
          category = transaction.investmentType!;
          date = transaction.dateInvested;
          amount = transaction.currentValue ?? transaction.initialValue;
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

  void _showAddOptions(BuildContext context, AppLocalizations localizations) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            _buildAddOption(localizations.translate('add_income'), Icons.attach_money, IncomeForm()),
            _buildAddOption(localizations.translate('add_expense'), Icons.shopping_cart, const ExpenseForm()),
            _buildAddOption(localizations.translate('add_investment'), Icons.show_chart, InvestmentForm()),
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
