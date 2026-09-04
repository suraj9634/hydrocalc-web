import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDsxW9iMmhs2pltUmJouZYb86CLZE0OuC0",
      authDomain: "hydrocalc-pro-c6ae3.firebaseapp.com",
      projectId: "hydrocalc-pro-c6ae3",
      storageBucket: "hydrocalc-pro-c6ae3.firebasestorage.app",
      messagingSenderId: "532868508252",
      appId: "1:532868508252:web:7147c3a58c01c12829d499",
      measurementId: "G-W5XG70ZNDH",
    ),
  );

  // Enable offline browser persistence for multi-operator caching
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

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
      home: const LoginScreen(),
    );
  }
}