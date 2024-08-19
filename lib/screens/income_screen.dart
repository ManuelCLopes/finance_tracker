import 'package:flutter/material.dart';
import '../databases/income_category_dao.dart';
import '../databases/income_dao.dart';
import '../models/income.dart';
import '../models/income_category.dart';
import '../utils/app_scaffold.dart';
import '../utils/no_data.dart';
import 'income_form.dart';
import 'package:intl/intl.dart';

class IncomeScreen extends StatefulWidget {
  final Key? key;
  IncomeScreen({this.key}) : super(key: key);

  @override
  _IncomeScreenState createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final IncomeDao _incomeDao = IncomeDao();
  final IncomeCategoryDao _incomeCategoryDao = IncomeCategoryDao();

  List<Income> _incomes = [];
  Map<int, String> _categoryMap = {}; // Map to hold category IDs and names
  bool _hasData = true;
  bool _isLoading = true; // Flag to indicate loading state
  double _totalMonthIncome = 0.0;
  String _monthLabel = 'Current Month'; // Label for the card, default is 'Current Month'
  ScrollController _scrollController = ScrollController();
  int _currentMonth = DateTime.now().month; // Track the current displayed month
  int _currentYear = DateTime.now().year;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData(); // Refresh data whenever dependencies change
  }

  void loadData() {
    _loadData(); // Public method to trigger data reload
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true; // Show loading indicator during data fetch
    });

    // Load categories and incomes
    List<IncomeCategory> categories = await _incomeCategoryDao.getAllCategories();
    List<Income> incomes = await _incomeDao.getAllIncomes();

    // Map category IDs to their names
    _categoryMap = {for (var category in categories) category.id!: category.name};

    // Calculate the initial values for the card based on the first income in the list
    if (incomes.isNotEmpty) {
      _currentMonth = DateTime.now().month;
      _currentYear = DateTime.now().year;
      _updateMonthLabel(_currentMonth, _currentYear, incomes);
    }

    setState(() {
      _incomes = incomes;
      _hasData = incomes.isNotEmpty;
      _isLoading = false; // Data loading is complete
    });
  }

  void _updateMonthLabel(int month, int year, List<Income> incomes) {
    DateTime now = DateTime.now();

    if (month == now.month && year == now.year) {
      _monthLabel = 'Current Month';
    } else {
      String monthName = DateFormat('MMMM').format(DateTime(year, month));
      _monthLabel = '$monthName $year';
    }

    // Calculate total income for that month
    double totalMonthIncome = incomes.where((income) {
      DateTime incomeDate = DateTime.parse(income.dateReceived);
      return incomeDate.month == month && incomeDate.year == year;
    }).fold(0.0, (sum, income) => sum + income.amount);

    setState(() {
      _totalMonthIncome = totalMonthIncome;
    });
  }

  void _onScrollUpdate() {
  if (_scrollController.hasClients) {
    double itemHeight = 100.0; // Average height of each item
    int firstVisibleIndex = (_scrollController.offset / itemHeight).floor();

    if (firstVisibleIndex >= 0 && firstVisibleIndex < _incomes.length) {
      DateTime firstVisibleDate = DateTime.parse(_incomes[firstVisibleIndex].dateReceived);
      int visibleMonth = firstVisibleDate.month;
      int visibleYear = firstVisibleDate.year;

      if (visibleMonth != _currentMonth || visibleYear != _currentYear) {
        _currentMonth = visibleMonth;
        _currentYear = visibleYear;
        _updateMonthLabel(visibleMonth, visibleYear, _incomes);
      }
    }
  }
}

  void _addOrEditIncome({Income? income}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncomeForm(income: income),
      ),
    );
    _loadData(); // Refresh data after adding or editing an income
  }

  void _deleteIncome(String incomeId) async {
    await _incomeDao.deleteIncome(incomeId);
    _loadData(); // Refresh data after deleting an income
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Income',
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasData
              ? _buildIncomeContent()
              : NoDataScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditIncome(),
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildIncomeContent() {
    // Group incomes by date in descending order
    Map<String, List<Income>> groupedIncomes = {};
    for (var income in _incomes) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(income.dateReceived));
      if (groupedIncomes.containsKey(formattedDate)) {
        groupedIncomes[formattedDate]!.add(income);
      } else {
        groupedIncomes[formattedDate] = [income];
      }
    }

    // Sort the dates in descending order
    List<String> sortedDates = groupedIncomes.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo is ScrollUpdateNotification) {
          _onScrollUpdate();
        }
        return true;
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display total income for the specific month in a card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _monthLabel, // Adjusted label based on first visible income
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '\$${_totalMonthIncome.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor, // Accent color for emphasis
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            // Build the list of incomes grouped by date
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  String date = sortedDates[index];
                  List<Income> incomesForDate = groupedIncomes[date]!;
                  return _buildIncomeGroup(date, incomesForDate);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeGroup(String date, List<Income> incomes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('MMMM dd, yyyy').format(DateTime.parse(date)),
          style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
        Column(
          children: incomes.map((income) {
            // Get category name using the category ID
            String categoryName = _categoryMap[income.categoryId] ?? 'Unknown';

            return ListTile(
              title: Text(categoryName),
              subtitle: Text(income.dateReceived),
              onTap: () => _addOrEditIncome(income: income),
              trailing: Text(
                '\$${income.amount.toStringAsFixed(2)}',
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
