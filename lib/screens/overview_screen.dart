import 'package:finance_tracker/utils/value_visibility_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:finance_tracker/screens/expense_form.dart';
import 'package:finance_tracker/screens/income_form.dart';
import 'package:finance_tracker/screens/investment_form.dart';
import 'package:intl/intl.dart';
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

  double _totalInvestments = 0.0;
  double _netWorth = 0.0;
  bool _hasData = true;
  bool _isLoading = true;
  String _currencySymbol = '\$'; // Default currency symbol

  DateTime _selectedDate = DateTime.now(); // Default to current month

  List<Income> _incomes = [];
  List<Expense> _expenses = [];
  List<Investment> _investments = [];
  List<dynamic> _lastTransactions = [];
  Map<int, String> _expenseCategoryMap = {};
  Map<int, String> _incomeCategoryMap = {};
  final PageController _pageController = PageController(initialPage: 0);

  double _pageViewIncome = 0.0;
  double _pageViewExpenses = 0.0;
  double _pageViewInvestments = 0.0;

  bool _isValueHidden = false;

  @override
  void initState() {
    super.initState(); 
    _loadVisibilityPreferences(); 
    _loadData();
  }

  Future<void> _loadVisibilityPreferences() async {
    _isValueHidden = await ValueVisibilityService.loadVisibilityPreference('isHidden');
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    List<ExpenseCategory> expenseCategories = await _expenseCategoryDao.getAllCategories();
    List<IncomeCategory> incomeCategories = await _incomeCategoryDao.getAllCategories();

    _expenseCategoryMap = {for (var category in expenseCategories) category.id!: category.name};
    _incomeCategoryMap = {for (var category in incomeCategories) category.id!: category.name};

    _incomes = await _incomeDao.getAllIncomes();
    _expenses = await _expenseDao.getAllExpenses();
    _investments = await _investmentDao.getAllInvestments();

    _currencySymbol = await CurrencyUtils.getCurrencySymbol();

    _calculateFixedData();
    _loadLastTransactions();
    _filterChartDataByMonth(_selectedDate);

    setState(() {
      _hasData = _incomes.isNotEmpty || _expenses.isNotEmpty || _investments.isNotEmpty;
      _isLoading = false;
    });
  }

  void _loadLastTransactions() {
    List<dynamic> transactions = [
      ..._incomes,
      ..._expenses,
      ..._investments,
    ];

    transactions.sort((a, b) {
      DateTime dateA;
      DateTime dateB;

      if (a is Income) {
        dateA = DateTime.parse(a.dateReceived);
      } else if (a is Expense) {
        dateA = DateTime.parse(a.dateSpent);
      } else if (a is Investment) {
        dateA = DateTime.parse(a.dateInvested);
      } else {
        return 0; // Fallback in case of unexpected data
      }

      if (b is Income) {
        dateB = DateTime.parse(b.dateReceived);
      } else if (b is Expense) {
        dateB = DateTime.parse(b.dateSpent);
      } else if (b is Investment) {
        dateB = DateTime.parse(b.dateInvested);
      } else {
        return 0;
      }

      return dateB.compareTo(dateA); // Sort by most recent first
    });

    setState(() {
      _lastTransactions = transactions.take(10).toList(); // Show last 10 transactions
    });
  }

  void _calculateFixedData() {
    double totalIncome = _incomes.fold(0.0, (sum, income) => sum + income.amount - income.taxAmount);
    double totalExpenses = _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    double totalInvestments = _investments.fold(0.0, (sum, investment) => sum + (investment.currentValue ?? 0.0));
    double totalInvested = _investments.fold(0.0, (sum, investment) => sum + (investment.initialValue));
    double netWorth = totalIncome - totalExpenses + totalInvestments - totalInvested;

    setState(() {
      _totalInvestments = totalInvestments;
      _netWorth = netWorth;
    });
  }

  void _filterChartDataByMonth(DateTime selectedDate) {
    final int selectedMonth = selectedDate.month;
    final int selectedYear = selectedDate.year;

    final filteredIncomes = _incomes.where((income) {
      final incomeDate = DateTime.parse(income.dateReceived);
      return incomeDate.month == selectedMonth && incomeDate.year == selectedYear;
    }).toList();

    final filteredExpenses = _expenses.where((expense) {
      final expenseDate = DateTime.parse(expense.dateSpent);
      return expenseDate.month == selectedMonth && expenseDate.year == selectedYear;
    }).toList();

    final filteredInvestments = _investments.where((investment) {
      final investmentDate = DateTime.parse(investment.dateInvested);
      return investmentDate.month == selectedMonth && investmentDate.year == selectedYear;
    }).toList();

    double totalIncome = filteredIncomes.fold(0.0, (sum, income) => sum + income.amount - income.taxAmount);
    double totalExpenses = filteredExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
    double totalInvestments = filteredInvestments.fold(0.0, (sum, investment) => sum + (investment.currentValue ?? 0.0));

    setState(() {
      _pageViewIncome = totalIncome;
      _pageViewExpenses = totalExpenses;
      _pageViewInvestments = totalInvestments;
    });
  }

  void _onPageChanged(int pageIndex) {
    final DateTime newDate = DateTime.now().subtract(Duration(days: pageIndex * 30));
    setState(() {
      _selectedDate = newDate;
    });
    _filterChartDataByMonth(newDate);
  }

  Future<void> _toggleValuesVisibility() async {
    setState(() {
      _isValueHidden = !_isValueHidden;
    });
    await ValueVisibilityService.saveVisibilityPreference('isHidden', _isValueHidden);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return AppScaffold(
      title: localizations?.translate('overview_title') ?? 'Overview',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasData
              ? _buildContent(localizations!)
              : _buildNoDataContent(),
      floatingActionButton: _hasData ? _buildFloatingActionButton(localizations!) : null,
    );
  }

  Widget _buildContent(AppLocalizations localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIncomeVsExpensesChart(localizations),
          const SizedBox(height: 16),
          _buildNetWorthSummary(localizations),
          const SizedBox(height: 8),
          _buildInvestmentSummary(localizations),
          const SizedBox(height: 32),
          _buildRecentTransactions(localizations),
        ],
      ),
    );
  }

  Widget _buildIncomeVsExpensesChart(AppLocalizations localizations) {
    final ThemeData theme = Theme.of(context);
    final bool isLightMode = theme.brightness == Brightness.light;
    final String assetName = isLightMode
        ? 'assets/images/savings_light.svg'
        : 'assets/images/savings_dark.svg';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.topCenter, // Align center to make it neat and minimalistic
          child: Chip(
            label: Text(
              _formatMonth(_selectedDate), // Minimal format for the selected month
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // Use primary color for better visibility
          ),
        ),
        SizedBox(
          height: 270, // Adjust height to fit chart and month label
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: 12, // Number of months to show
            itemBuilder: (context, index) {
              if (_pageViewIncome == 0.0 && _pageViewExpenses == 0.0 && _pageViewInvestments == 0.0) {
                return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      assetName,
                      width: 180,
                      height: 180,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.translate('no_data'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
              } else {
                return ThemedPieChart(
                  incomeValue: _pageViewIncome,
                  expenseValue: _pageViewExpenses,
                  investedValue: _pageViewInvestments,
                  currencySymbol: _currencySymbol,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  String _formatMonth(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  Widget _buildNetWorthSummary(AppLocalizations localizations) {
    return InkWell(
      splashColor: Colors.transparent, 
      highlightColor: Colors.transparent,
      onTap: _toggleValuesVisibility,
      child: Card(
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
                _isValueHidden ? '***********' : '${_netWorth.toStringAsFixed(2)} $_currencySymbol',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 123, 122, 122),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvestmentSummary(AppLocalizations localizations) {
    return InkWell(
      splashColor: Colors.transparent, 
      highlightColor: Colors.transparent,
      onTap: _toggleValuesVisibility, 
      child: Card(
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
              _isValueHidden ? '***********' : '${_totalInvestments.toStringAsFixed(2)} $_currencySymbol',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 123, 122, 122),
              ),
            ),
          ],
        ),
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

  Widget _buildNoDataContent() {
    final ThemeData theme = Theme.of(context);
    final bool isLightMode = theme.brightness == Brightness.light;
    final String assetName = isLightMode
        ? 'assets/images/savings_light.svg'
        : 'assets/images/savings_dark.svg';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'No Data Available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
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

  FloatingActionButton _buildFloatingActionButton(AppLocalizations localizations) {
    return FloatingActionButton(
      onPressed: () {
        _showAddOptions(context, localizations);
      },
      child: const Icon(Icons.add),
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
