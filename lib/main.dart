import 'package:air_quality_flutter/page/airpollution_page.dart';
import 'package:flutter/material.dart';

void main() => runApp(AirPollutionApp());

class AirPollutionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kvalita vzduchu v ČR',
      theme: new ThemeData(
          primarySwatch: Colors.green,
          primaryTextTheme: TextTheme(title: TextStyle(color: Colors.white))),
      home: AirPollutionPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
