import 'package:flutter/material.dart';
import '../databases/savings_dao.dart';
import '../models/savings.dart';
import '../utils/app_scaffold.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  _SavingsScreenState createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final SavingsDao _savingsDao = SavingsDao();
  List<Savings> _savings = [];

  @override
  void initState() {
    super.initState();
    _loadSavings();
  }

  Future<void> _loadSavings() async {
    // Replace with actual data retrieval.
    // _savings = await _savingsDao.getSavingsByUserId('user_id'); // Replace 'user_id' with actual user ID
    setState(() {
      _savings = [
        Savings(id: '1', userId: '1', goalName: 'Car', targetAmount: 20000, currentAmount: 5000, dateGoalSet: '2024-01-01'),
        Savings(id: '2', userId: '1', goalName: 'Vacation', targetAmount: 5000, currentAmount: 1000, dateGoalSet: '2024-01-15'),
      ];
    });
  }

  void _addSavings() async {
    Savings newSavings = Savings(id: '3', userId: '1', goalName: 'Emergency Fund', targetAmount: 10000, currentAmount: 2000, dateGoalSet: '2024-02-01');
    await _savingsDao.insertSavings(newSavings);
    _loadSavings();
  }

  void _deleteSavings(String savingsId) async {
    await _savingsDao.deleteSavings(savingsId);
    _loadSavings();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Savings',
      body: ListView.builder(
        itemCount: _savings.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_savings[index].goalName),
            subtitle: Text('Target: \$${_savings[index].targetAmount}, Current: \$${_savings[index].currentAmount}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteSavings(_savings[index].id),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSavings,
        child: const Icon(Icons.add),
      ),
    );
  }
}
