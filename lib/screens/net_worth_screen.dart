import 'package:flutter/material.dart';
import '../services/financial_service.dart';

class NetWorthScreen extends StatefulWidget {
  @override
  _NetWorthScreenState createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends State<NetWorthScreen> {
  final FinancialService _financialService = FinancialService();
  double _netWorth = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateNetWorth();
  }

  Future<void> _calculateNetWorth() async {
    // Replace 'user_id' with the actual user's ID.
    double netWorth = await _financialService.calculateNetWorth('user_id');
    setState(() {
      _netWorth = netWorth;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Net Worth'),
      ),
      body: Center(
        child: Text(
          'Your Net Worth: \$$_netWorth',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
