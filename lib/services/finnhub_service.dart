import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/currency_utils.dart';

class FinnhubService {
  static const String _apiKey = 'cr3gelpr01qk9rv5l7sgcr3gelpr01qk9rv5l7t0';
  static const String _baseUrl = 'https://finnhub.io/api/v1';
  static const String _exchangeRateApiUrl = 'https://api.exchangerate-api.com/v4/latest';

  // Fetch real-time stock data by symbol and convert to the desired currency
  static Future<double?> getRealTimeData(String symbol) async {
    final url = '$_baseUrl/quote?symbol=$symbol&token=$_apiKey';
    final String currencySymbol = await CurrencyUtils.getCurrencyLabel(); // Get the currency used in the app

    try {
      // Fetch stock price in the original currency
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final double stockPrice = data['c']; // 'c' field is the current price

        // Determine the currency of the stock's exchange (e.g., USD for US stocks)
        final String stockCurrency = await _getStockCurrency(symbol);

        // If the target currency is the same as the stock's currency, return the price directly
        if (stockCurrency == currencySymbol) {
          return stockPrice;
        }

        // Otherwise, fetch the exchange rate and convert the price
        final double exchangeRate = await _getExchangeRate(stockCurrency, currencySymbol);
        return stockPrice * exchangeRate;
      } else {
        print('Error fetching real-time data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception during fetching real-time data: $e');
      return null;
    }
  }

  // Fetch the currency in which the stock is traded (for simplicity, hardcoded here)
  static Future<String> _getStockCurrency(String symbol) async {
    // In a real implementation, this should be fetched based on the exchange
    // For example, NASDAQ stocks are traded in USD, so return 'USD'
    return 'USD';
  }

  // Fetch the exchange rate from one currency to another
  static Future<double> _getExchangeRate(String fromCurrency, String toCurrency) async {
    final url = '$_exchangeRateApiUrl/$fromCurrency';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['rates'][toCurrency];
      } else {
        print('Error fetching exchange rate: ${response.statusCode}');
        return 1.0;
      }
    } catch (e) {
      print('Exception during fetching exchange rate: $e');
      return 1.0; // Fallback to 1.0 in case of error, meaning no conversion
    }
  }

  // Fetch stock name by symbol (unchanged)
  static Future<String?> getStockName(String symbol) async {
    final url = '$_baseUrl/stock/profile2?symbol=$symbol&token=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['name']; // Stock name field in Finnhub API
      } else {
        print('Error fetching stock name: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception during fetching stock name: $e');
      return null;
    }
  }

  // Fetch historical data (unchanged)
  static Future<double?> getHistoricalData(String symbol, String date) async {
    final url = '$_baseUrl/quote?symbol=$symbol&token=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['c']; // 'c' field is the current price (close price in real-time)
      } else {
        print('Error fetching historical data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception during fetching historical data: $e');
      return null;
    }
  }
}
