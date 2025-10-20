import 'package:flutter/material.dart';
import 'package:foodfleet/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodfleet/Theme/theme_provider.dart';
import 'appView.dart';
import 'services/auth_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ Auth Service Provider
        Provider<DatabaseService>(
          create: (_) => DatabaseService(),
        ),

        // ✅ Firebase Auth User Stream (Live updates on profile changes)
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: FirebaseAuth.instance.currentUser,
        ),

        // ✅ Theme Provider
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: const AppView(),
    );
  }
}
