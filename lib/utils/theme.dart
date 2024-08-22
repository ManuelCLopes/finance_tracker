import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF2C3E50),
    hintColor: const Color(0xFFB8860B),
    fontFamily: 'Georgia',

    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2C3E50), 
      secondary: Color(0xFFB8860B), 
      onPrimary: Color(0xFFF5F5DC),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF2C3E50),
      onSecondary: Color(0xFFF5F5DC),
      error: Color(0xFFB00020),
      onError: Color(0xFFFFFFFF), 
    ),
    
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 36.0, 
        fontWeight: FontWeight.bold, 
        color: Color(0xFF004B3A), 
      ),
      titleLarge: TextStyle(
        fontSize: 18.0, 
        fontStyle: FontStyle.normal, 
        color: Color(0xFF2C3E50),
      ),
      bodyMedium: TextStyle(
        fontSize: 14.0, 
        fontFamily: 'Hind', 
        color: Color(0xFF2C3E50), 
      ),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2C3E50),
      titleTextStyle: TextStyle(
        color: Color.fromARGB(255, 254, 251, 245), 
        fontSize: 20, 
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(
        color: Color.fromARGB(255, 254, 251, 245),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF2C3E50),
      unselectedItemColor: Color(0xFF8B8B8B),
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF2C3E50), 
      foregroundColor: Color(0xFFF5F5DC), 
    ),

    cardColor: const Color(0xFFF5F5DC), 
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    iconTheme: const IconThemeData(
      color: Color(0xFF2C3E50),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2C3E50), 
        foregroundColor: Colors.white, 
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );

   static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color.fromARGB(255, 254, 251, 245),
    hintColor: const Color(0xFFB39B72),
    scaffoldBackgroundColor: const Color.fromARGB(255, 14, 9, 0),

    colorScheme: const ColorScheme.dark(
      primary: Color.fromARGB(255, 254, 251, 245),
      secondary: Color(0xFFB39B72),
      onPrimary: Color(0xFF2C3E50), 
      surface: Color(0xFF2C2C2C),
      onSurface: Color.fromARGB(255, 254, 251, 245),
      onSecondary: Color(0xFF1C1C1C),
      error: Color(0xFFB00020), 
      onError: Color(0xFFFFFFFF),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 14, 9, 0),
      titleTextStyle: TextStyle(color: Color.fromARGB(255, 254, 251, 245), fontSize: 20, fontWeight: FontWeight.bold),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color.fromARGB(255, 0, 12, 6),
      selectedItemColor: Color(0xFFB39B72), 
      unselectedItemColor: Color(0xFF696969),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF1C1C1C), 
      foregroundColor: Color.fromARGB(255, 254, 251, 245),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 36.0, 
        fontWeight: FontWeight.bold, 
        color: Color.fromARGB(255, 254, 251, 245),
      ),
      titleLarge: TextStyle(
        fontSize: 18.0, 
        fontStyle: FontStyle.normal, 
        color: Color.fromARGB(255, 254, 251, 245),
      ),
      bodyMedium: TextStyle(
        fontSize: 14.0, 
        fontFamily: 'Hind', 
        color: Color.fromARGB(255, 254, 251, 245),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1C1C1C), 
        foregroundColor: const Color.fromARGB(255, 254, 251, 245),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      focusColor: const Color(0xFFB39B72), 
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF696969)),
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFB39B72), width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      labelStyle: const TextStyle(color: Color(0xFFB39B72)),
      hintStyle: const TextStyle(color: Color(0xFFB0B0B0)), 
    ),

    datePickerTheme: DatePickerThemeData(
      backgroundColor: const Color(0xFF1C1C1C),
      headerForegroundColor: const Color(0xFFB39B72), 
      dayForegroundColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFB39B72); 
        }
        return const Color.fromARGB(255, 254, 251, 245);
      }),
      yearForegroundColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFB39B72);
        }
        return const Color.fromARGB(255, 254, 251, 245);
      }),
      todayForegroundColor: WidgetStateColor.resolveWith((states) {
        return const Color(0xFFB39B72);
      }),
    ),
  );
}
