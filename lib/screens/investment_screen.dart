import 'package:flutter/material.dart';
import '../databases/investment_dao.dart';
import '../models/investment.dart';
import '../utils/no_data.dart';
import 'investment_form.dart';

class InvestmentScreen extends StatefulWidget {
  final Key? key;

  InvestmentScreen({this.key}) : super(key: key);

  @override
  _InvestmentScreenState createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  final InvestmentDao _investmentDao = InvestmentDao();
  List<Investment> _investments = [];
  bool _hasData = true;
  bool _isLoading = true;
  double _totalInvested = 0.0;
  double _totalInitial = 0.0;
  double _percentageReturn = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  void loadData() {
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final investments = await _investmentDao.getInvestmentsByUserId('1'); // Replace with actual user ID
    double totalInvested = investments.fold(0.0, (sum, investment) => sum + investment.currentValue);
    double totalInitial = investments.fold(0.0, (sum, investment) => sum + investment.initialValue);

    double percentageReturn = totalInitial > 0 ? ((totalInvested - totalInitial) / totalInitial) * 100 : 0;

    setState(() {
      _investments = investments;
      _totalInvested = totalInvested;
      _totalInitial = totalInitial;
      _percentageReturn = percentageReturn;
      _hasData = investments.isNotEmpty;
      _isLoading = false;
    });
  }

  void _addOrEditInvestment({Investment? investment}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvestmentForm(investment: investment),
      ),
    );
    _loadData();
  }

  void _deleteInvestment(String investmentId) async {
    await _investmentDao.deleteInvestment(investmentId);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Investments'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasData ? _buildInvestmentContent() : NoDataScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditInvestment(),
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildInvestmentContent() {
    // Group investments by type
    Map<String, List<Investment>> groupedInvestments = {};
    for (var investment in _investments) {
      if (groupedInvestments.containsKey(investment.investmentType)) {
        groupedInvestments[investment.investmentType]!.add(investment);
      } else {
        groupedInvestments[investment.investmentType] = [investment];
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display total invested amount and percentage return in a card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Invested',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${_totalInvested.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_percentageReturn.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _percentageReturn >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          // Build the list of investments grouped by type
          Expanded(
            child: ListView.builder(
              itemCount: groupedInvestments.keys.length,
              itemBuilder: (context, index) {
                String category = groupedInvestments.keys.elementAt(index);
                List<Investment> investmentsForCategory = groupedInvestments[category]!;
                return _buildInvestmentGroup(category, investmentsForCategory);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentGroup(String category, List<Investment> investments) {
    // Calculate the total initial and current values for the category
    double totalInitial = investments.fold(0.0, (sum, investment) => sum + investment.initialValue);
    double totalCurrent = investments.fold(0.0, (sum, investment) => sum + investment.currentValue);

    // Calculate the percentage of return or loss
    double percentageReturn = totalInitial > 0 ? ((totalCurrent - totalInitial) / totalInitial) * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              category,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8), // Space between category and value
            Text(
              '\$${totalCurrent.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium, // Regular font for value
            ),
            SizedBox(width: 8), // Space between value and percentage
            Text(
              '${percentageReturn.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 16, // Regular font size
                color: percentageReturn >= 0 ? Colors.green : Colors.red, // Green for gain, red for loss
              ),
            ),
          ],
        ),
        Column(
          children: investments.map((investment) {
            return ListTile(
              title: Text('Initial: \$${investment.initialValue.toStringAsFixed(2)}'),
              subtitle: Text('Current: \$${investment.currentValue.toStringAsFixed(2)}'),
              trailing: Text(
                investment.dateInvested,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              onTap: () => _addOrEditInvestment(investment: investment),
            );
          }
        ).toList(),
      ),
      Divider(),
    ],
  );
}

}
