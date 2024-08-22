import 'dart:convert';
import 'package:http/http.dart' as http;

class FinnhubService {
  static const String _apiKey = 'cr3gelpr01qk9rv5l7sgcr3gelpr01qk9rv5l7t0'; // Replace with your actual Finnhub API key
  static const String _baseUrl = 'https://finnhub.io/api/v1';

  // Fetch real-time stock data by symbol
  static Future<double?> getRealTimeData(String symbol) async {
    final url = '$_baseUrl/quote?symbol=$symbol&token=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['c']; // 'c' field is the current (close) price
      } else {
        print('Error fetching real-time data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception during fetching real-time data: $e');
      return null;
    }
  }

  // Fetch stock name by symbol
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

  // Fetch historical data (close price) for a specific date
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
