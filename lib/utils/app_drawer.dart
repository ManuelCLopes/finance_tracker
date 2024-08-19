import 'package:flutter/material.dart';
import '../screens/backup_screen.dart';
import '../screens/category_management_screen.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Text(
              'Finance Tracker',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.category),
            title: Text('Manage Categories'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CategoryManagementScreen()),
              );
            },
          ),
           ListTile(
            leading: Icon(Icons.backup),
            title: Text('Backup & Restore'),
            onTap: () {
              Navigator.pop(context); // Fechar o drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BackupScreen()),
              );
            },
          ),
          // Add more ListTiles here for additional menu items if needed
        ],
      ),
    );
  }
}
