import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/app_localizations_service.dart';

class ThemedPieChart extends StatelessWidget {
  final double incomeValue;
  final double expenseValue;
  final double investedValue;
  final String currencySymbol;

  const ThemedPieChart({super.key, 
    required this.incomeValue,
    required this.expenseValue,
    required this.investedValue,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final bool isLightTheme = theme.brightness == Brightness.light;
    final Color labelTextColor = isLightTheme ? const Color(0xFF3B3029) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: [
                _buildPieChartSection(
                  value: incomeValue,
                  color: const Color(0xFF3B3029), // Black Coffee
                ),
                _buildPieChartSection(
                  value: expenseValue,
                  color: const Color(0xFF592E2D), // Hot Chocolate
                ),
                _buildPieChartSection(
                  value: investedValue,
                  color: const Color(0xFFA57C55), // Gold Leaf
                ),
              ],
              centerSpaceRadius: 30,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  if (event is FlTapUpEvent) {
                    if (pieTouchResponse != null && pieTouchResponse.touchedSection != null) {
                      final PieChartSectionData? sectionData = pieTouchResponse.touchedSection!.touchedSection;
                      _showTotalDialog(context, sectionData!);
                    }
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildPieChartLabels(labelTextColor, context),
      ],
    );
  }

  PieChartSectionData _buildPieChartSection({
    required double value,
    required Color color,
  }) {
    return PieChartSectionData(
      color: color,
      value: value,
      radius: 60,
      title: '',
    );
  }

  Widget _buildPieChartLabels(Color labelTextColor, BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPieChartLabel(localizations!.translate('income'), const Color(0xFF3B3029), labelTextColor),  // Black Coffee
        _buildPieChartLabel(localizations.translate('expenses'), const Color(0xFF592E2D), labelTextColor),  // Hot Chocolate
        _buildPieChartLabel(localizations.translate('invested'), const Color(0xFFA57C55), labelTextColor),  // Gold Leaf
      ],
    );
  }

  Widget _buildPieChartLabel(String text, Color color, Color labelTextColor) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(text, style: TextStyle(color: labelTextColor)),
      ],
    );
  }

  void _showTotalDialog(BuildContext context, PieChartSectionData sectionData) {
    String sectionTitle;
    if (sectionData.color == const Color(0xFF3B3029)) {
      sectionTitle = 'Income';
    } else if (sectionData.color == const Color(0xFF592E2D)) {
      sectionTitle = 'Expenses';
    } else if (sectionData.color == const Color(0xFFA57C55)) {
      sectionTitle = 'Investments';
    } else {
      sectionTitle = 'Unknown';
    }

    final formattedTotal = "${sectionData.value.toStringAsFixed(2)} $currencySymbol";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            sectionTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                formattedTotal,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 18),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
