import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Make sure this points to your login screen

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HydroCalcApp());
}

class HydroCalcApp extends StatelessWidget {
  const HydroCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barrage Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
      ),
      home: const LoginScreen(), // This ensures the app starts at the Login Screen!
    );
  }
}