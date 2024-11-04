import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpensesPieChart extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> monthlyAveragesFuture;

  const ExpensesPieChart({super.key, required this.monthlyAveragesFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: monthlyAveragesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading data'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No data available'));
        } else {
          return _buildPieChart(snapshot.data!, context);
        }
      },
    );
  }

  Widget _buildPieChart(List<Map<String, dynamic>> data, BuildContext context) {
    final List<Color> colors = Colors.primaries;

    List<PieChartSectionData> sections = data.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> item = entry.value;
      return PieChartSectionData(
        value: item['monthly_average'],
        color: colors[index % colors.length],
        radius: 50,
        showTitle: false, // Hide titles initially
      );
    }).toList();

    bool isDialogShown = false;

    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
          borderData: FlBorderData(show: false),
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              if (pieTouchResponse != null &&
                  pieTouchResponse.touchedSection != null &&
                  !isDialogShown) {
                isDialogShown = true;
                final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                final touchedEntry = data[index];
                final category = touchedEntry['category'];
                final monthlyAverage = touchedEntry['monthly_average'];

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(category),
                      content: Text('Monthly Average: \$${monthlyAverage.toStringAsFixed(2)}'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('OK'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            isDialogShown = false; // Reset dialog flag
                          },
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
