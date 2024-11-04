import 'package:flutter/material.dart';

class TopExpensesTable extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> monthlyAveragesFuture;
  final Future<List<Map<String, dynamic>>> lastMonthExpensesFuture;

  const TopExpensesTable({
    super.key,
    required this.monthlyAveragesFuture,
    required this.lastMonthExpensesFuture,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: monthlyAveragesFuture,
      builder: (context, monthlyAveragesSnapshot) {
        if (monthlyAveragesSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (monthlyAveragesSnapshot.hasError) {
          return Center(child: Text('Error loading monthly averages'));
        } else if (!monthlyAveragesSnapshot.hasData || monthlyAveragesSnapshot.data!.isEmpty) {
          return Center(child: Text('No data available for monthly averages'));
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: lastMonthExpensesFuture,
          builder: (context, lastMonthExpensesSnapshot) {
            if (lastMonthExpensesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (lastMonthExpensesSnapshot.hasError) {
              return Center(child: Text('Error loading last month expenses'));
            } else if (!lastMonthExpensesSnapshot.hasData || lastMonthExpensesSnapshot.data!.isEmpty) {
              return Center(child: Text('No data available for last month expenses'));
            }

            // Extract data after both futures have completed
            List<Map<String, dynamic>> monthlyAverages = monthlyAveragesSnapshot.data!;
            List<Map<String, dynamic>> lastMonthExpenses = lastMonthExpensesSnapshot.data!;

            // Combine data based on category
            List<Map<String, dynamic>> combinedData = [];
            for (var avg in monthlyAverages) {
              var lastMonth = lastMonthExpenses.firstWhere(
                (exp) => exp['category'] == avg['category'],
                orElse: () => {'total_last_month': 0.0},
              );
              combinedData.add({
                'category': avg['category'],
                'monthly_average': avg['monthly_average'],
                'total_last_month': lastMonth['total_last_month'] ?? 0.0,
              });
            }

            // Sort and take the top 5
            combinedData.sort((a, b) => b['monthly_average'].compareTo(a['monthly_average']));
            combinedData = combinedData.take(5).toList();

            return _buildTopExpensesTable(combinedData);
          },
        );
      },
    );
  }

  Widget _buildTopExpensesTable(List<Map<String, dynamic>> data) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DataTable(
        columnSpacing: 24.0,
        columns: const [
          DataColumn(
            label: Text(
              '',
            ),
          ),
          DataColumn(
            label: Text(
              'Average',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'Last Month',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
        ],
        rows: data.map((entry) {
          final double monthlyAverage = entry['monthly_average'];
          final double lastMonthTotal = entry['total_last_month'];

          return DataRow(
            cells: [
              DataCell(Text(entry['category'], style: const TextStyle(fontSize: 14))),
              DataCell(Text(monthlyAverage.toStringAsFixed(2), style: const TextStyle(fontSize: 14))),
              DataCell(
                Text(
                  lastMonthTotal.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 14,
                    color: lastMonthTotal > monthlyAverage ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
