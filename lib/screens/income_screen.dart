import 'package:flutter/material.dart';
import '../databases/income_dao.dart';
import '../models/income.dart';
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
  List<Income> _incomes = [];
  bool _hasData = true;
  bool _isLoading = true; // Flag to indicate loading state
  double _totalCurrentMonthIncome = 0.0;

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

    List<Income> incomes = await _incomeDao.getAllIncomes();
    double totalCurrentMonthIncome = 0.0;

    DateTime now = DateTime.now();
    int currentMonth = now.month;
    int currentYear = now.year;

    for (var income in incomes) {
      DateTime incomeDate = DateTime.parse(income.dateReceived);

      if (incomeDate.month == currentMonth && incomeDate.year == currentYear) {
        totalCurrentMonthIncome += income.amount;
      }
    }
    print("Total Income for ${DateFormat('MMMM').format(now)}: $totalCurrentMonthIncome");

    setState(() {
      _incomes = incomes;
      _hasData = incomes.isNotEmpty;
      _totalCurrentMonthIncome = totalCurrentMonthIncome;
      _isLoading = false; // Data loading is complete
    });
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Income'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasData ? _buildIncomeContent() : NoDataScreen(),
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display total income for the current month in a card
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
                    '\$${_totalCurrentMonthIncome.toStringAsFixed(2)}',
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
            return ListTile(
              title: Text(income.source),
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
