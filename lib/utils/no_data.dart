import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NoDataScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          SvgPicture.asset(
                    'assets/images/no_data.svg', 
                    width: 150,
                    height: 150,
                  ),            
            SizedBox(height: 16),
            const Text(
              'No records found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ]
      ),
      )
    );
  }
}
