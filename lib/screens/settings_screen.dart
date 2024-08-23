import 'package:flutter/material.dart';
import '../services/app_localizations_service.dart';
import '../services/localization_service.dart';
import '../utils/currency_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedCurrency = '';
  late Locale _selectedLocale;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      String currency = await CurrencyUtils.getCurrencySymbol();
      Locale locale = LocalizationService().getCurrentLocale();

      setState(() {
        _selectedCurrency = currency;
        _selectedLocale = locale;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle the error appropriately
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load settings. Please try again.')),
      );
    }
  }

  void _updateCurrency(String? value) {
    if (value != null) {
      setState(() {
        _selectedCurrency = value;
      });
      CurrencyUtils.saveCurrencySymbol(value);
    }
  }

  void _updateLanguage(Locale? locale) {
    if (locale != null) {
      setState(() {
        _selectedLocale = locale;
      });
      LocalizationService().setLocale(locale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations?.translate('settings_title') ?? 'Settings'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.translate('settings_title') ?? 'Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(localizations?.translate('select_currency') ?? 'Select Currency Symbol'),
              trailing: DropdownButton<String>(
                value: _selectedCurrency,
                items: const [
                  DropdownMenuItem(value: '\$', child: Text('\$')),
                  DropdownMenuItem(value: '€', child: Text('€')),
                  DropdownMenuItem(value: '£', child: Text('£')),
                  DropdownMenuItem(value: '¥', child: Text('¥')),
                ],
                onChanged: _updateCurrency,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(localizations?.translate('select_language') ?? 'Select Language'),
              trailing: DropdownButton<Locale>(
                value: _selectedLocale,
                items: const [
                  DropdownMenuItem(value: Locale('en'), child: Text('English')),
                  DropdownMenuItem(value: Locale('pt'), child: Text('Português')),
                  DropdownMenuItem(value: Locale('es'), child: Text('Español')),
                  DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
                ],
                onChanged: _updateLanguage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
