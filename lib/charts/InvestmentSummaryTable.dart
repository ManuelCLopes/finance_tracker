import 'package:flutter/material.dart';

class InvestmentSummaryTable extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> investmentSummariesFuture;

  const InvestmentSummaryTable({super.key, required this.investmentSummariesFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: investmentSummariesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar os dados'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Não há dados de investimento disponíveis'));
        } else {
          return _buildInvestmentSummaryTable(snapshot.data!);
        }
      },
    );
  }

  Widget _buildInvestmentSummaryTable(List<Map<String, dynamic>> data) {
    return DataTable(
      columnSpacing: 20,
      columns: const [
        DataColumn(
          label: Text(
            'Type',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Initial',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Current',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
      rows: data.map((entry) {
        final String investmentType = entry['type'];
        final double totalInitialValue = entry['total_initial_value'];
        final double totalCurrentValue = entry['total_current_value'];

        return DataRow(
          cells: [
            DataCell(Text(investmentType)),
            DataCell(Text(totalInitialValue.toStringAsFixed(2))),
            DataCell(
              Text(
                totalCurrentValue.toStringAsFixed(2),
                style: TextStyle(
                  color: totalCurrentValue >= totalInitialValue ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
