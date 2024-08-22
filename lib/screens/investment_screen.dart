import 'package:flutter/material.dart';
import '../models/investment.dart';
import '../databases/investment_dao.dart';
import '../utils/app_scaffold.dart';
import '../utils/currency_utils.dart';
import '../services/alpha_vantage_service.dart';
import 'investment_form.dart';  // Ensure you import the InvestmentForm

class InvestmentScreen extends StatefulWidget {
  final Key? key;
  const InvestmentScreen({this.key}) : super(key: key);

  @override
  _InvestmentScreenState createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  final InvestmentDao _investmentDao = InvestmentDao();
  String _currencySymbol = '\$'; // Default currency symbol

  List<Investment> _investments = [];
  bool _isLoading = true;
  double _totalInvested = 0.0;
  double _totalCurrentValue = 0.0;
  double _percentageChange = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Fetch the currency symbol
    _currencySymbol = await CurrencyUtils.getCurrencySymbol();

    // Fetch investments from the database
    List<Investment> investments = await _investmentDao.getAllInvestments();

    // Calculate initial total invested and current value
    double totalInvested = investments.fold(0.0, (sum, inv) => sum + inv.initialValue);
    double totalCurrentValue = investments.fold(0.0, (sum, inv) => sum + (inv.currentValue ?? inv.initialValue));

    // Update the UI with the fetched investments
    setState(() {
      _investments = investments;
      _totalInvested = totalInvested;
      _totalCurrentValue = totalCurrentValue;
      _percentageChange = (totalCurrentValue - totalInvested) / totalInvested * 100;
      _isLoading = false;
    });

    // Fetch real-time data for each investment and update the UI
    _updateInvestmentsWithRealTimeData();
  }

  Future<void> _updateInvestmentsWithRealTimeData() async {
    double updatedTotalCurrentValue = 0.0;

    for (var investment in _investments) {
      final realTimeData = await _fetchRealTimeData(investment.symbol);
      if (realTimeData != null) {
        double currentValue = double.parse(realTimeData['05. price']);
        updatedTotalCurrentValue += currentValue;

        Investment updatedInvestment = Investment(
          id: investment.id,
          symbol: investment.symbol,
          investmentType: investment.investmentType,
          initialValue: investment.initialValue,
          currentValue: currentValue,
          dateInvested: investment.dateInvested,
        );

        setState(() {
          _investments[_investments.indexOf(investment)] = updatedInvestment;
        });
      } else {
        updatedTotalCurrentValue += investment.currentValue ?? investment.initialValue;
      }
    }

    // Recalculate totals after updating all investments
    setState(() {
      _totalCurrentValue = updatedTotalCurrentValue;
      _percentageChange = (_totalCurrentValue - _totalInvested) / _totalInvested * 100;
    });
  }

  Future<Map<String, dynamic>?> _fetchRealTimeData(String? symbol) async {
    if (symbol == null || symbol.isEmpty) return null;

    try {
      final data = await AlphaVantageService.getRealTimeData(symbol);
      return data;
    } catch (e) {
      print('Error fetching real-time data: $e');
      return null;
    }
  }

  void _addOrEditInvestment({Investment? investment}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvestmentForm(investment: investment),
      ),
    );
    _loadData(); // Reload data after adding or editing an investment
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Investments',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildInvestmentContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditInvestment(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInvestmentContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildGroupedInvestmentList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final Color percentageColor = _percentageChange >= 0 ? Colors.green : Colors.red;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16.0), // Space below the card
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Inner padding for content
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Label Text
            Text(
              'Total Invested',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            // Value and Percentage Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_totalInvested.toStringAsFixed(2)} $_currencySymbol',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4), // Space between value and percentage
                Text(
                  '${_percentageChange.toStringAsFixed(2)} %',
                  style: TextStyle(
                    color: percentageColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        )
      )
    );
  }

  Widget _buildGroupedInvestmentList() {
    // Group investments by type
    Map<String, List<Investment>> groupedInvestments = {};
    for (var investment in _investments) {
      groupedInvestments.putIfAbsent(investment.investmentType!, () => []).add(investment);
    }

    // Build the grouped list
    return Column(
      children: groupedInvestments.entries.map((entry) {
        double totalInitial = entry.value.fold(0.0, (sum, inv) => sum + inv.initialValue);
        double totalCurrent = entry.value.fold(0.0, (sum, inv) => sum + (inv.currentValue ?? inv.initialValue));
        double categoryChange = (totalCurrent - totalInitial) / totalInitial * 100;

        final Color categoryPercentageColor = categoryChange >= 0 ? Colors.green : Colors.red;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${categoryChange.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: categoryPercentageColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.map((investment) {
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16.0),
                child: InkWell(
                  onTap: () => _addOrEditInvestment(investment: investment),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            investment.symbol ?? 'Unknown Symbol',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${investment.currentValue?.toStringAsFixed(2)} $_currencySymbol',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_calculateIndividualPercentageChange(investment).toStringAsFixed(2)} %',
                              style: TextStyle(
                                color: _calculateIndividualPercentageChange(investment) >= 0 ? Colors.green : Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      }).toList(),
    );
  }

  double _calculateIndividualPercentageChange(Investment investment) {
    return ((investment.currentValue ?? investment.initialValue) - investment.initialValue) / investment.initialValue * 100;
  }
}
