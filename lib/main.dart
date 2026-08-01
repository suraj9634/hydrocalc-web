import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const HydroCalcApp());
}

class HydroCalcApp extends StatelessWidget {
  const HydroCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HydroCalc Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}
