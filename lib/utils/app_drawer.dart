import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../screens/backup_screen.dart';
import '../screens/category_management_screen.dart';
import '../screens/data_share_screen.dart';
import '../services/app_localizations_service.dart';
import 'theme_provider.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();

    String adUnitId;
  
    if (Platform.isAndroid) {
      adUnitId = 'ca-app-pub-3263443288403750/6624915495';
    } else if (Platform.isIOS) {
      adUnitId = 'ca-app-pub-3263443288403750/2494127044'; 
    } 
    else {
      adUnitId = '';
    }

    _bannerAd = BannerAd(
      adUnitId: adUnitId, //test id: ca-app-pub-3940256099942544/6300978111
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Falha ao carregar o banner: ${err.message}');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    var localization = AppLocalizations.of(context);

    return Drawer(
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Text(
                  'Finance Tracker',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
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
                title: isDarkMode
                    ? Text(localization.translate('dark_mode'))
                    : Text(localization.translate('light_mode')),
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
                  Navigator.pop(context); // Fecha o drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DataEntryScreen()),
                  );
                },
              ),
            ],
          ),
          // Banner Ad Section - fixed at the bottom
          if (_isBannerAdReady)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                alignment: Alignment.center,
                child: AdWidget(ad: _bannerAd!),
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
              ),
            ),
        ],
      ),
    );
  }
}