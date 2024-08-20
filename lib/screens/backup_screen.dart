import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/backup_frequency_dialog.dart';
import '../utils/backup_helper.dart';

class BackupScreen extends StatefulWidget {
  @override
  _BackupScreenState createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  String? _selectedFrequency;

  @override
  void initState() {
    super.initState();
    _loadSavedFrequency();
  }

  Future<void> _loadSavedFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedFrequency = prefs.getString('backup_frequency');
    });
  }

  void _openFrequencySelector() {
    showDialog(
      context: context,
      builder: (context) => BackupFrequencyDialog(
        selectedFrequency: _selectedFrequency,
        onFrequencySelected: (frequency) async {
          setState(() {
            _selectedFrequency = frequency;
          });
          if (frequency != null) {
            await BackupHelper.scheduleBackup(frequency: frequency);
          }
        },
        onUnschedule: () async {
          setState(() {
            _selectedFrequency = null;
          });
          await BackupHelper.unscheduleBackup();
        },
      ),
    );
  }

  Future<void> _exportToJson() async {
    final filePath = await BackupHelper.exportToJson();
    if (filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup saved as JSON in $filePath')),
      );
    }
  }

  Future<void> _exportToCsv() async {
    final filePath = await BackupHelper.exportToCsv();
    if (filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup saved as CSV in $filePath')),
      );
    }
  }

  Future<void> _importFromJson() async {
    await BackupHelper.importFromJson();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data restored from JSON')),
    );
  }

  Future<void> _importFromCsv() async {
    await BackupHelper.importFromCsv();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data restored from CSV')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_selectedFrequency != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Scheduled Backup: $_selectedFrequency',
                ),
              ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                children: [
                  _buildSquareButton('Export to JSON', Icons.file_copy, _exportToJson),
                  _buildSquareButton('Export to CSV', Icons.table_chart, _exportToCsv),
                  _buildSquareButton('Import JSON', Icons.file_download, _importFromJson),
                  _buildSquareButton('Import CSV', Icons.file_upload, _importFromCsv),
                  _buildSquareButton('Backup \nScheduling', Icons.schedule, _openFrequencySelector),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareButton(String title, IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, 
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 40.0),
              const SizedBox(height: 8.0),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}