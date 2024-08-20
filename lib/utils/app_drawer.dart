import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/backup_screen.dart';
import '../screens/category_management_screen.dart';
import 'theme_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text(
              'Finance Tracker',
              style: Theme.of(context).textTheme.headlineMedium),
            ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Manage Categories'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CategoryManagementScreen()),
              );
            },
          ),
           ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup & Restore'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BackupScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            title: Text(isDarkMode ? 'Dark Mode' : 'Light Mode'),
            onTap: () {
              themeProvider.toggleTheme(!isDarkMode);
            },
          ),
        ],
      ),
    );
  }
}
