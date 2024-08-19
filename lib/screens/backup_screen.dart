import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../utils/backup_helper.dart';

class BackupScreen extends StatefulWidget {
  @override
  _BackupScreenState createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Backup & Restore'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Data',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final filePath = await BackupHelper.exportToJson();
                if (filePath != null) {
                  _showSnackBarWithOpenOption(filePath, 'Exported to JSON');
                }
              },
              child: Text('Export to JSON'),
            ),
            ElevatedButton(
              onPressed: () async {
                final filePath = await BackupHelper.exportToCsv();
                if (filePath != null) {
                  _showSnackBarWithOpenOption(filePath, 'Exported to CSV');
                }
              },
              child: Text('Export to CSV'),
            ),
            SizedBox(height: 30),
            Text(
              'Import Data',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await BackupHelper.importFromJson();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported from JSON')));
              },
              child: Text('Import from JSON'),
            ),
            ElevatedButton(
              onPressed: () async {
                await BackupHelper.importFromCsv();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported from CSV')));
              },
              child: Text('Import from CSV'),
            ),
            SizedBox(height: 30),
            Text(
              'Backup Scheduling',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                BackupHelper.scheduleBackup('weekly');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup scheduled')));
              },
              child: Text('Schedule Weekly Backup'),
            ),
            ElevatedButton(
              onPressed: () {
                BackupHelper.unscheduleBackup();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup unscheduled')));
              },
              child: Text('Unschedule Backup'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBarWithOpenOption(String filePath, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {
            OpenFile.open(filePath);
          },
        ),
      ),
    );
  }
}
