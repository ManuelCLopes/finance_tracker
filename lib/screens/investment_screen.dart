import 'package:finance_tracker/services/crypto_service.dart';
import 'package:finance_tracker/utils/value_visibility_utils.dart';
import 'package:flutter/material.dart';
import '../models/investment.dart';
import '../databases/investment_dao.dart';
import '../services/app_localizations_service.dart';
import '../utils/app_scaffold.dart';
import '../utils/currency_utils.dart';
import '../services/finnhub_service.dart';
import '../utils/no_data.dart';
import 'investment_form.dart';

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

  Future<void> _loadData() async {
    // Fetch the currency symbol
    _currencySymbol = await CurrencyUtils.getCurrencySymbol();

    // Fetch investments from the database (initially saved data)
    List<Investment> investments = await _investmentDao.getAllInvestments();

    // Calculate initial total invested
    double totalInvested = investments.fold(0.0, (sum, inv) => sum + inv.initialValue);

    // Set state with initial values (render screen with saved values)
    setState(() {
      _investments = investments;
      _totalInvested = totalInvested;
      _isLoading = false;  // Screen will be rendered with saved data
    });

    // Fetch real-time data and update investments asynchronously
    _updateInvestmentsWithCurrentValue();  // This will update the values behind the scenes
  }

  Future<void> _updateInvestmentsWithCurrentValue() async {
    double updatedTotalCurrentValue = 0.0;

    for (var investment in _investments) {
      if (investment.investmentType == 'Stocks' || investment.investmentType == 'ETFs') {
        final currentPrice = await _fetchRealTimeData(investment.symbol);
        if (currentPrice != null) {
          final quantity = investment.initialValue / currentPrice;
          final currentValue = (quantity * currentPrice).roundToDouble();
          updatedTotalCurrentValue += currentValue;

          Investment updatedInvestment = investment.copyWith(
            quantity: quantity,
            currentValue: currentValue,
          );

          await _investmentDao.updateInvestment(updatedInvestment);

          setState(() {
            _investments[_investments.indexOf(investment)] = updatedInvestment;
          });
        } else {
          updatedTotalCurrentValue += investment.currentValue ?? investment.initialValue;
        }
      } else if (investment.investmentType == 'Cryptocurrency') {
        final cryptoDetails = await CryptoService().getCryptoDetails(investment.symbol ?? '');
        if (cryptoDetails != null) {
          final cryptoPrice = cryptoDetails['current_price']?.toDouble() ?? 1.0;
          final quantity = investment.initialValue / cryptoPrice;
          final currentValue = (quantity * cryptoPrice).roundToDouble();
          updatedTotalCurrentValue += currentValue;

          Investment updatedInvestment = investment.copyWith(
            quantity: quantity,
            currentValue: currentValue,
          );

          await _investmentDao.updateInvestment(updatedInvestment);

          setState(() {
            _investments[_investments.indexOf(investment)] = updatedInvestment;
          });
        } else {
          updatedTotalCurrentValue += investment.currentValue ?? investment.initialValue;
        }
      } else if (investment.investmentType == 'Constant Return') {
        final currentValue = _calculateConstantReturnCurrentValue(investment);
        updatedTotalCurrentValue += currentValue;

        Investment updatedInvestment = investment.copyWith(
          currentValue: currentValue,
        );

        await _investmentDao.updateInvestment(updatedInvestment);

        setState(() {
          _investments[_investments.indexOf(investment)] = updatedInvestment;
        });
      } else {
        updatedTotalCurrentValue += investment.currentValue ?? investment.initialValue;
      }
    }

    setState(() {
      _totalCurrentValue = updatedTotalCurrentValue;
      _percentageChange = (_totalCurrentValue - _totalInvested) / _totalInvested * 100;
    });
  }

  double _calculateConstantReturnCurrentValue(Investment investment) {
    final initialDate = DateTime.parse(investment.dateInvested);
    final currentDate = DateTime.now();
    final durationMonths = _getDurationInMonths(investment.duration ?? '-');
    final endDate = initialDate.add(Duration(days: 30 * durationMonths));

    if (currentDate.isAfter(endDate) && durationMonths != 0) {
      // If the current date is after the investment period, cap the value at the duration end
      final yearsPassed = durationMonths / 12;
      return investment.initialValue * (1 + (investment.annualReturn! / 100) * yearsPassed);
    } else {
      // Calculate the value based on the time passed within the investment period
      final yearsPassed = currentDate.difference(initialDate).inDays / 365.25;
      return investment.initialValue * (1 + (investment.annualReturn! / 100) * yearsPassed);
    }
  }

  int _getDurationInMonths(String duration) {
    switch (duration) {
      case '3 months':
        return 3;
      case '6 months':
        return 6;
      case '12 months':
        return 12;
      default:
        return 0;
    }
  }

  Future<double?> _fetchRealTimeData(String? symbol) async {
    if (symbol == null || symbol.isEmpty) return null;

    try {
      final currentPrice = await FinnhubService.getRealTimeData(symbol);
      if (currentPrice == null) {
        print('No data found for symbol: $symbol');
      }
      return currentPrice;
    } catch (e) {
      print('Error fetching real-time data for symbol: $symbol - $e');
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
    final localizations = AppLocalizations.of(context);

    return AppScaffold(
      title: localizations!.translate('investments'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _investments.isEmpty 
              ? NoDataScreen()
              : _buildInvestmentContent(context, localizations),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditInvestment(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInvestmentContent(BuildContext context, AppLocalizations? localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(context, localizations),
          const SizedBox(height: 16),
          _buildGroupedInvestmentList(context, localizations),
        ],
      ),
    );
  }

  Future<void> _toggleValuesVisibility() async {
    setState(() {
      _isValueHidden = !_isValueHidden;
    });
    await ValueVisibilityService.saveVisibilityPreference('isHidden', _isValueHidden);
  }

  Widget _buildSummaryCard(BuildContext context, AppLocalizations? localizations) {
    final Color percentageColor = _percentageChange >= 0 ? Colors.green : Colors.red;

    return InkWell(
      splashColor: Colors.transparent, 
      highlightColor: Colors.transparent,
      onTap: _toggleValuesVisibility,
      child: Card(
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
                localizations!.translate('total_invested'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              // Value and Percentage Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _isValueHidden ? '***********' : '${_totalInvested.toStringAsFixed(2)} $_currencySymbol',
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
          ),
        ),
      ), 
    );
  }

  Widget _buildGroupedInvestmentList(BuildContext context, AppLocalizations? localizations) {
    Map<String, List<Investment>> groupedInvestments = {};
    for (var investment in _investments) {
      groupedInvestments.putIfAbsent(investment.investmentType!, () => []).add(investment);
    }

    return Column(
      children: groupedInvestments.entries.map((entry) {
        double totalInitial = entry.value.fold(0.0, (sum, inv) => sum + inv.initialValue);
        double totalCurrent = entry.value.fold(0.0, (sum, inv) => sum + (inv.currentValue ?? inv.initialValue));
        double categoryChange = (totalCurrent - totalInitial) / totalInitial * 100;

        final Color categoryPercentageColor = categoryChange >= 0 ? Colors.green : Colors.red;

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations?.translate(entry.key.toLowerCase()) ?? entry.key,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${categoryChange.toStringAsFixed(2)} %',
                  style: TextStyle(
                    color: categoryPercentageColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            children: entry.value.map((investment) {
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
                            investment.investmentProduct ?? localizations!.translate('unknown_product'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              investment.currentValue != null
                                  ? '${investment.currentValue!.toStringAsFixed(2)} $_currencySymbol'
                                  : localizations!.translate('not_available'),
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
          )
        );
      }).toList(),
    );
  }

  double _calculateIndividualPercentageChange(Investment investment) {
    return ((investment.currentValue ?? investment.initialValue) - investment.initialValue) / investment.initialValue * 100;
  }
}
