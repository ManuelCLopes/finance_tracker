import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'screens/settings_screen.dart';
import 'utils/backup_helper.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';
import 'utils/theme_provider.dart';
import 'services/localization_service.dart';
import 'services/app_localizations_service.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'backupTask':
        // Directly call the backup method here
        await BackupHelper.scheduledBackup();
        break;
    }
    return Future.value(true);  // Return true to indicate task completion
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  // Initialize WorkManager for background tasks
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,  // Set to true for debugging; false for release builds
  );

  await dotenv.load(fileName: ".env");
  
    runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocalizationService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localizationService = Provider.of<LocalizationService>(context);

    return MaterialApp(
      title: 'Finance Tracker',
      locale: localizationService.getCurrentLocale(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('pt'), // Portuguese
        Locale('es'), // Spanish
        Locale('fr'), // French
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) {
          return supportedLocales.first;
        }

        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }

        return supportedLocales.first;
      },
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
