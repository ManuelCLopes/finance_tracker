import 'package:finance_tracker/charts/ExpensesPieChart.dart';
import 'package:finance_tracker/charts/InvestmentSummaryTable.dart';
import 'package:finance_tracker/charts/MonthlyIncomeBarChart.dart';
import 'package:finance_tracker/charts/TopExpensesTable.dart';
import 'package:finance_tracker/charts/TopIncomeSourcesTable.dart';
import 'package:flutter/material.dart';
import '../databases/database_helper.dart';
import '../services/app_localizations_service.dart';

class DataVisualizationScreen extends StatefulWidget {
  const DataVisualizationScreen({super.key});

  @override
  _DataVisualizationScreenState createState() => _DataVisualizationScreenState();
}

class _DataVisualizationScreenState extends State<DataVisualizationScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('dataVisualization')),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSectionTitle(context, 'expenses'),
            ExpensesPieChart(monthlyAveragesFuture: _dbHelper.getMonthlyAverageExpenses()),
            TopExpensesTable(monthlyAveragesFuture: _dbHelper.getMonthlyAverageExpenses(), lastMonthExpensesFuture: _dbHelper.getLastMonthExpenses(),),
            _buildSectionTitle(context, 'incomes'),
            MonthlyIncomeBarChart(monthlyIncomeSumsFuture: _dbHelper.getMonthlyIncomeSums()),
            TopIncomeSourcesTable(top5IncomeSourcesFuture: _dbHelper.getTop5IncomeSources()),
            _buildSectionTitle(context, 'investments'),
            InvestmentSummaryTable(investmentSummariesFuture: _dbHelper.getInvestmentSummaries()),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String key) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        AppLocalizations.of(context)!.translate(key),
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
