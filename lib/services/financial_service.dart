import '../databases/expense_dao.dart';
import '../databases/income_dao.dart';
import '../databases/investment_dao.dart';
import '../databases/savings_dao.dart';

class FinancialService {
  final IncomeDao incomeDao = IncomeDao();
  final ExpenseDao expenseDao = ExpenseDao();
  final InvestmentDao investmentDao = InvestmentDao();
  final SavingsDao savingDao = SavingsDao();

  Future<double> calculateNetWorth(String userId) async {
    final incomes = await incomeDao.getIncomesByUserId(userId);
    final expenses = await expenseDao.getExpensesByUserId(userId);
    final investments = await investmentDao.getInvestmentsByUserId(userId);
    final savings = await savingDao.getSavingsByUserId(userId);

    double totalIncome = incomes.fold(0, (sum, item) => sum + item.amount);
    double totalExpense = expenses.fold(0, (sum, item) => sum + item.amount);
    double totalInvestments = investments.fold(0, (sum, item) => sum + item.currentValue);
    double totalSavings = savings.fold(0, (sum, item) => sum + item.currentAmount);

    return totalIncome + totalInvestments + totalSavings - totalExpense;
  }
}
