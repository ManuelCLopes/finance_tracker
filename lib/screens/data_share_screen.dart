import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../databases/database_helper.dart';

class DataEntryScreen extends StatefulWidget {
  @override
  _DataEntryScreenState createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String sessionId = '';  // Variable to store session ID
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isNavigating = false;  // Add a flag to prevent multiple navigations

  @override
  void dispose() {
    controller?.dispose();  // Dispose the controller when the screen is disposed
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (_isNavigating) return;  // Prevent navigation if already navigating

      if (scanData.code != null) {
        Uri uri = Uri.parse(scanData.code!);
        sessionId = uri.queryParameters['sessionid'] ?? '';

        setState(() {
          _isNavigating = true;  // Set the flag to true before navigation
        });

        if (mounted) { // Check if widget is still mounted
          await _fetchAndSendData();
          if (mounted) {
            Navigator.pop(context);  // Navigate back to the home screen after sending data
          }
        }

        controller.stopCamera();  // Stop camera after scanning

        setState(() {
          _isNavigating = false;  // Reset the flag after navigation
        });
      } else {
        print('Scan data is null');
      }
    });
  }

  Future<void> _fetchAndSendData() async {
    if (sessionId.isEmpty) {
      if (!mounted) return; // Stop if the widget is no longer mounted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session ID is missing! Please scan the QR code again.')),
      );
      return;
    }

    // Fetch data from SQLite
    List<Map<String, dynamic>> expenses = await _dbHelper.getAllExpenses();
    List<Map<String, dynamic>> incomes = await _dbHelper.getAllIncomes();
    List<Map<String, dynamic>> investments = await _dbHelper.getAllInvestments();

    final Uri url = Uri.parse('http://192.168.1.78:8000/receive_all_data/');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Cookie': 'sessionid=$sessionId',
    };

    final String body = json.encode({
      'expenses': expenses,
      'incomes': incomes,
      'investments': investments,
    });

    try {
      final http.Response response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201) {
        print('Data sent successfully!');
        if (mounted) { // Check if widget is still mounted
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data sent successfully!')),
          );
        }
      } else {
        print('Failed to send data: ${response.body}');
        if (mounted) { // Check if widget is still mounted
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send data: ${response.body}')),
          );
        }
      }
    } catch (error) {
      print('Error sending data: $error');
      if (mounted) { // Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
