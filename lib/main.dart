import 'package:air_quality_flutter/page/homepage.dart';
import 'package:flutter/material.dart';

void main() => runApp(AirPollutionApp());

class AirPollutionApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kvalita vzduchu v ČR',
      theme: ThemeData.light(),
      home: HomePage(),
    );
  }
}
