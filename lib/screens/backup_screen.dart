import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/backup_frequency_dialog.dart';
import '../utils/backup_helper.dart';
import '../services/app_localizations_service.dart'; // Import your localization service

class BackupScreen extends StatefulWidget {
  @override
  _BackupScreenState createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  String? _selectedFrequency;
  final BackupHelper _backupHelper = BackupHelper();

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
            await BackupHelper.scheduleBackupTask(context: context, frequency: frequency);
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
        SnackBar(content: Text('${AppLocalizations.of(context)?.translate('backup_saved_json')} $filePath')),
      );
    }
  }

  Future<void> _importFromJson() async {
    await _backupHelper.importFromJson(context); // Use instance
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)?.translate('data_restored_json') ?? 'Data restored from JSON')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.translate('backup_restore') ?? 'Backup & Restore'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_selectedFrequency != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '${AppLocalizations.of(context)?.translate('scheduled_backup')}: ${AppLocalizations.of(context)?.translate(_selectedFrequency!.toLowerCase())}',
                ),
              ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                children: [
                  _buildSquareButton(AppLocalizations.of(context)?.translate('export_to_json') ?? 'Export to JSON', Icons.file_copy, _exportToJson),
                  _buildSquareButton(AppLocalizations.of(context)?.translate('import_json') ?? 'Import JSON', Icons.file_download, _importFromJson),
                  _buildSquareButton(AppLocalizations.of(context)?.translate('backup_scheduling') ?? 'Backup \nScheduling', Icons.schedule, _openFrequencySelector),
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
