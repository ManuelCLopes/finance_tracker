import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ThemedPieChart extends StatelessWidget {
  final double incomeValue;
  final double expenseValue;
  final double investedValue;

  ThemedPieChart({
    required this.incomeValue,
    required this.expenseValue,
    required this.investedValue,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Use a darker color for labels in the light theme for better readability
    final bool isLightTheme = theme.brightness == Brightness.light;
    final Color labelTextColor = isLightTheme ? const Color(0xFF3B3029) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estimated Net Worth',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
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
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildPieChartLabels(labelTextColor),
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

  Widget _buildPieChartLabels(Color labelTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPieChartLabel('Income', const Color(0xFF3B3029), labelTextColor),  // Black Coffee
        _buildPieChartLabel('Expenses', const Color(0xFF592E2D), labelTextColor),  // Hot Chocolate
        _buildPieChartLabel('Invested', const Color(0xFFA57C55), labelTextColor),  // Gold Leaf
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
}
