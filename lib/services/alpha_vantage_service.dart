import 'dart:convert';
import 'package:http/http.dart' as http;

class AlphaVantageService {
  static const String _apiKey = 'NKWGLUBI6GJN0TUW';
  static const String _baseUrl = 'https://www.alphavantage.co/query';

  static Future<Map<String, dynamic>?> getRealTimeData(String symbol) async {
    final url = Uri.parse(
        '$_baseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['Global Quote'] as Map<String, dynamic>?;
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }
}
