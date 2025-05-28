import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../pos_order_screen.dart';
import '../screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );        }        if (snapshot.hasData && snapshot.data != null) {
          final syncService = SyncService();
          print("AuthGate: User is logged in - UID: ${snapshot.data!.uid}, syncing menu data...");
          syncService.fetchMenuFromFirebasePaginated().then((_) {
            syncService.listenToMenuUpdatesFromFirebase();
          });
          return const PosOrderScreen();
        }
        print("AuthGate: User is not logged in.");
        return const LoginScreen();
      },
    );
  }
} 