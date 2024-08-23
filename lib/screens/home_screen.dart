import 'package:flutter/material.dart';
import 'overview_screen.dart';
import 'expense_screen.dart';
import 'income_screen.dart';
import 'investment_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Create GlobalKeys to access the states of the screens
  final GlobalKey _overviewKey = GlobalKey();
  final GlobalKey _incomeKey = GlobalKey();
  final GlobalKey _investmentKey = GlobalKey();

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // Initialize the screens list here
    _screens = [
      OverviewScreen(key: _overviewKey),
      ExpenseScreen(),
      IncomeScreen(key: _incomeKey),
      InvestmentScreen(key: _investmentKey),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _refreshCurrentScreen(index);
    });
  }

  void _refreshCurrentScreen(int index) {
    if (index == 0) {
      (_overviewKey.currentState as dynamic)?.loadData();
    } else if (index == 2) {
      (_incomeKey.currentState as dynamic)?.loadData();
    } else if (index == 3) {
      (_investmentKey.currentState as dynamic)?.loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopify_outlined),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money_outlined),
            label: 'Income',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Investments',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
