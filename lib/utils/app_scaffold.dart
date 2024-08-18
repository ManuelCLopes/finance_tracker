import 'package:flutter/material.dart';
import 'app_drawer.dart'; // Import the reusable AppDrawer

class AppScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final FloatingActionButton? floatingActionButton; // Optional FAB

  AppScaffold({
    required this.body,
    required this.title,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      drawer: AppDrawer(), // Use the reusable drawer
      body: body, // Display the screen's content
      floatingActionButton: floatingActionButton, // Include the FAB if provided
    );
  }
}
