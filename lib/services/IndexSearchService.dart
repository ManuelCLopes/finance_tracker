import 'package:flutter/material.dart';

class IndexSearchService {
  static void searchIndex(
    String input, 
    BuildContext context, 
    Function(String symbol, String name) onSelectETF,
  ) {
    input = input.trim().toUpperCase();

    if (input.contains("S&P 500") || input == "SP500") {
      _showIndexETFOptions(context, 'S&P 500', [
        {'symbol': 'SPY', 'name': 'SPDR S&P 500 ETF Trust'},
        {'symbol': 'IVV', 'name': 'iShares Core S&P 500 ETF'},
        {'symbol': 'VOO', 'name': 'Vanguard S&P 500 ETF'},
      ], onSelectETF);
    } else if (input.contains("NASDAQ") || input.contains("NDX")) {
      _showIndexETFOptions(context, 'NASDAQ-100', [
        {'symbol': 'QQQ', 'name': 'Invesco QQQ Trust'},
        {'symbol': 'TQQQ', 'name': 'ProShares UltraPro QQQ'},
        {'symbol': 'SQQQ', 'name': 'ProShares UltraPro Short QQQ'},
      ], onSelectETF);
    } else if (input.contains("DOW JONES") || input.contains("DJIA")) {
      _showIndexETFOptions(context, 'Dow Jones Industrial Average', [
        {'symbol': 'DIA', 'name': 'SPDR Dow Jones Industrial Average ETF Trust'},
      ], onSelectETF);
    } else if (input.contains("RUSSELL 2000")) {
      _showIndexETFOptions(context, 'Russell 2000', [
        {'symbol': 'IWM', 'name': 'iShares Russell 2000 ETF'},
      ], onSelectETF);
    } else if (input.contains("FTSE 100")) {
      _showIndexETFOptions(context, 'FTSE 100', [
        {'symbol': 'ISF', 'name': 'iShares FTSE 100 ETF'},
      ], onSelectETF);
    } else if (input.contains("DAX")) {
      _showIndexETFOptions(context, 'DAX', [
        {'symbol': 'EWG', 'name': 'iShares MSCI Germany ETF'},
        {'symbol': 'DAX', 'name': 'Global X DAX Germany ETF'},
      ], onSelectETF);
    } else {
      // Handle other cases or return null
      onSelectETF('', ''); // Or any suitable fallback
    }
  }

  static void _showIndexETFOptions(
    BuildContext context, 
    String indexName, 
    List<Map<String, String>> options,
    Function(String symbol, String name) onSelectETF,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('Select an $indexName ETF'),
          children: options.map((option) {
            return SimpleDialogOption(
              onPressed: () {
                onSelectETF(option['symbol']!, option['name']!);
                Navigator.pop(context);
              },
              child: Text('${option['symbol']} - ${option['name']}'),
            );
          }).toList(),
        );
      },
    );
  }
}
