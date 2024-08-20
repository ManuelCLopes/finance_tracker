import 'package:flutter/material.dart';
import 'app_drawer.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final FloatingActionButton? floatingActionButton; // Optional FAB
  final List<IconButton>? actions; // Optional Actions list

  const AppScaffold({super.key, 
    required this.body,
    required this.title,
    this.floatingActionButton, 
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      drawer: AppDrawer(),
      body: body, 
      floatingActionButton: floatingActionButton,
    );
  }
}
