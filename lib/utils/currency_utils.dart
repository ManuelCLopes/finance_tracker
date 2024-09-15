import 'package:shared_preferences/shared_preferences.dart';

class CurrencyUtils {
  static const String _currencyKey = 'currencySymbol';
  static const String defaultCurrency = '\$'; // Define the default currency here

  static Future<void> saveCurrencySymbol(String symbol) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, symbol);
  }

  static Future<String> getCurrencySymbol() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? defaultCurrency;
  }

  static Future<String> getCurrencyLabel() async {
    String symbol = await getCurrencySymbol();
    switch (symbol) {
      case '\$':
        return 'USD';
      case '€':
        return 'EUR';
      case '£':
        return 'GBP';
      case '¥':
        return 'JPY';
      default:
        return 'Unknown Currency';
    }
  }

}
