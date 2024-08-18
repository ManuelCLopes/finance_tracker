import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(FinanceTrackerApp());
}

class FinanceTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      theme: ThemeData(
        // Define the default brightness and colors
        brightness: Brightness.light,
        primaryColor: Color(0xFF004B3A), // Deep Green
        hintColor: Color(0xFFB8860B),  // Gold Accents

        // Define the default font family
        fontFamily: 'Georgia',

        // Define the default TextTheme
        textTheme: TextTheme(
          displayLarge: TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold, color: Color(0xFF004B3A)), // Deep Green
          titleLarge: TextStyle(fontSize: 18.0, fontStyle: FontStyle.normal, color: Color(0xFF2C3E50)), // Dark Blue
          bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Hind', color: Color(0xFF2C3E50)), // Dark Blue
        ),

        // Customize the app bar
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF004B3A), // Deep Green
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        // Customize the bottom navigation bar
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF2C3E50), // Dark Blue
          selectedItemColor: Color(0xFFB8860B), // Gold Accents
          unselectedItemColor: Color(0xFFF5F5DC), // Beige
        ),

        // Define the default card color and shape
        cardColor: Color(0xFFF5F5DC), // Beige
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // Customize buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Color(0xFF800020),
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        // Customize the icon themes
        iconTheme: IconThemeData(
          color: Color(0xFF8B4513), // Brown
        ),
      ),
      home: HomeScreen(), // Your HomeScreen or OverviewScreen
    );
  }
}
