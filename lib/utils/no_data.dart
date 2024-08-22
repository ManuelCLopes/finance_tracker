import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NoDataScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool isLightMode = Theme.of(context).brightness == Brightness.light;

    // Choose the appropriate SVG file based on the theme
    final String assetName = isLightMode
        ? 'assets/images/no_data_light.svg'  // Path to your light mode SVG
        : 'assets/images/no_data_dark.svg';  // Path to your dark mode SVG

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              assetName, 
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 16),
            const Text(
              'No records found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
