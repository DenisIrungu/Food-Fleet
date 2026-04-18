import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/super_admin_init.dart';

void main() async {
  print('🚀 Starting FoodFleet...');
  WidgetsFlutterBinding.ensureInitialized();

  print('🔥 Initializing Firebase...');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully!');
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      print('⚠️ Firebase already initialized, skipping...');
    } else {
      rethrow;
    }
  }

  // ✅ Initialize App Check — debug for mobile, skip for web
  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    print('✅ App Check initialized!');
  }

  print('👤 Initializing Super Admin...');
  final superAdminInit = SuperAdminInitService();
  await superAdminInit.initializeSuperAdmin();
  print('✅ Super Admin ready!');

  print('🎬 Launching app...');
  runApp(const MyApp());
}
