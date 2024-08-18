import 'package:finance_tracker/models/savings.dart';

class SavingsTracker {
  double calculateProgress(Savings savings) {
    return (savings.currentAmount / savings.targetAmount) * 100;
  }
}
