import 'package:flutter/material.dart';
import '../utils/currency_utils.dart'; // Assuming CurrencyUtils is in the utils folder

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedCurrency = '';

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    String currency = await CurrencyUtils.getCurrencySymbol();
    setState(() {
      _selectedCurrency = currency;
    });
  }

  void _updateCurrency(String? value) {
    if (value != null) {
      setState(() {
        _selectedCurrency = value;
      });
      CurrencyUtils.saveCurrencySymbol(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero, // Removes padding
              title: const Text('Select Currency Symbol'),
              trailing: DropdownButton<String>(
                value: _selectedCurrency,
                items: const [
                  DropdownMenuItem(
                    value: '\$', // Dollar symbol
                    child: Text('\$'),
                  ),
                  DropdownMenuItem(
                    value: '€', // Euro symbol
                    child: Text('€'),
                  ),
                  DropdownMenuItem(
                    value: '£', // Pound symbol
                    child: Text('£'),
                  ),
                  DropdownMenuItem(
                    value: '¥', // Yen symbol
                    child: Text('¥'),
                  ),
                ],
                onChanged: _updateCurrency,
              ),
            ),
            // Future configuration rows can be added here.
          ],
        ),
      ),
    );
  }
}
