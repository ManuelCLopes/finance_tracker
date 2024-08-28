import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/backup_screen.dart';
import '../screens/category_management_screen.dart';
import '../screens/data_share_screen.dart';
import '../services/app_localizations_service.dart';
import 'theme_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    var localization = AppLocalizations.of(context);


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
            title: Text(localization!.translate('manage_categories')),
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
            title: Text(localization.translate('backup_restore')),
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
            title: isDarkMode ? 
            Text(localization.translate('dark_mode')) : 
            Text(localization.translate('light_mode')),
            onTap: () {
              themeProvider.toggleTheme(!isDarkMode);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(localization.translate('settings')),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: Text(localization.translate('view_on_web')),
            onTap: () {
              Navigator.pop(context);  // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DataEntryScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
