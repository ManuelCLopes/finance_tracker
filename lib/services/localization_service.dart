import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class LocalizationService extends ChangeNotifier{
  static final LocalizationService _instance = LocalizationService._internal();

  factory LocalizationService() {
    return _instance;
  }

  LocalizationService._internal();

  Locale _currentLocale = const Locale('en'); // Default to English

  Locale getCurrentLocale() {
    return _currentLocale;
  }

  void setLocale(Locale locale) {
    _currentLocale = locale;
    notifyListeners();
  }

  static Iterable<Locale> get supportedLocales => [
        const Locale('en'),
        const Locale('pt'),
        const Locale('es'),
        const Locale('fr'),
      ];

  static Iterable<LocalizationsDelegate<dynamic>> get localizationsDelegates => [
        // Add your app-specific localization delegates here
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];
}
