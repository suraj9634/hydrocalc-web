import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() async {
  // 1. Add this print statement to see if Dart is executing
  print("DEBUG: main() function has started!");

  // 2. This is REQUIRED if you have 'async' in main or initialize services here
  WidgetsFlutterBinding.ensureInitialized(); 

  // (Your other initialization code if any)

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
