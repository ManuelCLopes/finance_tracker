import 'package:finance_tracker/models/investment.dart';

class InvestmentTracker {
  double calculatePerformance(Investment investment) {
    return ((investment.currentValue - investment.initialValue) / investment.initialValue) * 100;
  }
}
