import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/currency_utils.dart';

class CryptoService {
  final String _baseUrl = 'https://api.coingecko.com/api/v3';
  final String _apiKey = 'CG-3c5hqTz3ntS7nvvxscmM3e5z';

  Future<Map<String, dynamic>?> getCryptoDetails(String symbol) async {
    try {
      final String cryptoId = _convertSymbolToId(symbol);
      final String currencyLabel = await CurrencyUtils.getCurrencyLabel(); // Get the currency used in the app

      // Fetch price data with an API key
      final response = await http.get(
        Uri.parse('$_baseUrl/simple/price?ids=$cryptoId&vs_currencies=$currencyLabel'),
        headers: {
          'x-cg-demo-api-key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty && data[cryptoId] != null) {
          return {
            'name': _capitalize(cryptoId),  // Capitalize the first letter
            'current_price': data[cryptoId][currencyLabel.toLowerCase()],
          };
        }
      } else {
        print('Error: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load cryptocurrency details');
    }
    return null;
  }

  String _convertSymbolToId(String symbol) {
    final Map<String, String> symbolToId = {
      'btc': 'bitcoin',
      'eth': 'ethereum',
      'ltc': 'litecoin',
      // Add more as needed
    };
    return symbolToId[symbol.toLowerCase()] ?? symbol.toLowerCase();
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

}
