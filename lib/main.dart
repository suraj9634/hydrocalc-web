import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

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

  // Enable offline browser persistence with unlimited local cache
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const HydroCalcApp());
}

// 1. Root App Widget with persistent session detection
class HydroCalcApp extends StatelessWidget {
  const HydroCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if operator has a cached session (works even when completely offline)
    final User? cachedUser = FirebaseAuth.instance.currentUser;
    final bool hasActiveSession = cachedUser != null;

    return MaterialApp(
      title: 'Barrage Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
      ),
      home: hasActiveSession
          ? HomePage(currentRole: cachedUser.displayName ?? cachedUser.email ?? 'Operator')
          : const LoginScreen(),
    );
  }
}

// 2. Global Sync Status Badge Widget
class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('discharge_logs')
          .limit(1)
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        // Fallback indicator while initial stream connection initializes
        if (!snapshot.hasData || snapshot.hasError) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade400, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  "Standby",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          );
        }

        final bool hasPendingWrites = snapshot.data!.metadata.hasPendingWrites;
        final bool isFromCache = snapshot.data!.metadata.isFromCache;
        final bool isSynced = !hasPendingWrites && !isFromCache;

        return Tooltip(
          message: isSynced ? "All logs synced to Cloud" : "Saving locally (Offline)",
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSynced
                  ? Colors.green.withOpacity(0.15)
                  : Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSynced ? Colors.green : Colors.amber.shade700,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSynced ? Icons.cloud_done : Icons.cloud_queue,
                  size: 16,
                  color: isSynced ? Colors.green.shade700 : Colors.amber.shade800,
                ),
                const SizedBox(width: 6),
                Text(
                  isSynced ? "Cloud Synced" : "Saved Offline",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSynced ? Colors.green.shade800 : Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}