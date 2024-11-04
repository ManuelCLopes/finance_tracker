import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MonthlyIncomeBarChart extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> monthlyIncomeSumsFuture;

  const MonthlyIncomeBarChart({super.key, required this.monthlyIncomeSumsFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: monthlyIncomeSumsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar os dados de rendimentos'));
        } else if (!snapshot.hasData) {
          return Center(child: Text('Não há dados disponíveis'));
        } else {
          final data = _fillMissingMonths(snapshot.data!);
          return _buildBarChart(data);
        }
      },
    );
  }

  List<Map<String, dynamic>> _fillMissingMonths(List<Map<String, dynamic>> data) {
    final now = DateTime.now();
    Map<int, double> monthlyIncomeMap = {
      for (int i = 1; i <= 12; i++) i: 0.0, // Preenche todos os meses com 0
    };

    // Atualiza o mapa com os valores reais
    for (var entry in data) {
      int month = int.parse(entry['month']);
      monthlyIncomeMap[month] = entry['total_income']?.toDouble() ?? 0.0;
    }

    // Retorna uma lista preenchida com dados até o mês atual
    return [
      for (int i = 1; i <= now.month; i++)
        {'month': i, 'total_income': monthlyIncomeMap[i]}
    ];
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    List<BarChartGroupData> barGroups = data.map((entry) {
      int month = entry['month'];
      double totalIncome = entry['total_income'];

      return BarChartGroupData(
        x: month,
        barRods: [
          BarChartRodData(
            toY: totalIncome,
            color: Colors.blueAccent,
            width: 15,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final month = DateFormat('MMM').format(DateTime(0, value.toInt()));
                  return Text(
                    month,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
