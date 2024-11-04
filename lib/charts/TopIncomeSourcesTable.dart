import 'package:flutter/material.dart';

class TopIncomeSourcesTable extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> top5IncomeSourcesFuture;

  const TopIncomeSourcesTable({super.key, required this.top5IncomeSourcesFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: top5IncomeSourcesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar os dados'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Não há dados de rendimento disponíveis'));
        } else {
          return _buildIncomeSourcesTable(snapshot.data!);
        }
      },
    );
  }

  Widget _buildIncomeSourcesTable(List<Map<String, dynamic>> data) {
    return DataTable(
      columnSpacing: 20,
      columns: const [
        DataColumn(
          label: Text(
            '',
          ),
        ),
        DataColumn(
          label: Text(
            'Total Acumulado',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
      rows: data.map((entry) {
        final String category = entry['category'];
        final double totalIncome = entry['total_income'];

        return DataRow(
          cells: [
            DataCell(Text(category)),
            DataCell(
              Text(
                totalIncome.toStringAsFixed(2),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
