import 'package:finance_tracker/models/income.dart';

class TaxCalculator {
  double calculateTax(Income income, double taxRate) {
    return income.amount * taxRate;
  }
}
