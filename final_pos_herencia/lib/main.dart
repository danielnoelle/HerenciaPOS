import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';
import 'package:final_pos_herencia/services/sync_service.dart';
import 'package:final_pos_herencia/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final SyncService syncService = SyncService();
  final AuthService authService = AuthService();

  syncService.startPeriodicTimerBasedSync();

  if (authService.currentUser != null) {
    developer.log("Main: User is logged in, performing initial sync and starting listeners.", name: "main");
    await syncService.syncAllData(isManualSync: true);
    syncService.listenToMenuUpdatesFromFirebase();
  } else {
    developer.log("Main: No user logged in at startup. Sync/Listeners will start after login.", name: "main");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SyncService _syncService = SyncService();
  final AuthService _authService = AuthService();
  StreamSubscription? _authSubscription;
  @override
  void initState() {
    super.initState();
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        developer.log("MyApp: Auth state changed - User logged IN. Starting menu sync and listeners.", name: "main");
        _syncService.fetchMenuFromFirebasePaginated().then((_) {
          _syncService.listenToMenuUpdatesFromFirebase();
          _syncService.syncAllData(isManualSync: true);
        });
      } else {
        developer.log("MyApp: Auth state changed - User logged OUT. Stopping listeners.", name: "main");
        _syncService.stopListeningToMenuUpdates();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _syncService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'La Herencia POS',
      theme: ThemeData(
                fontFamily: 'Poppins',
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black54),
          titleTextStyle: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w500, fontFamily: 'Poppins')
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)
          )
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: Colors.orange.shade600,
          secondarySelectedColor: Colors.orange.shade600,
          labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
          secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade300)
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          iconTheme: IconThemeData(color: Colors.orange.shade700, size: 18)
        ),
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Poppins'),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}
