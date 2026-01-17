import 'package:flutter/material.dart';
import 'package:foodfleet/services/category_service.dart';
import 'package:foodfleet/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodfleet/Theme/theme_provider.dart';
import 'appView.dart';

// 🔽 NEW
import 'package:foodfleet/providers/restaurant_scope_provider.dart';
import 'package:foodfleet/services/menu_service.dart';
import 'package:foodfleet/services/addon_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ Database Service
        Provider<DatabaseService>(
          create: (_) => DatabaseService(),
        ),

        // ✅ Firebase Auth User Stream
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: FirebaseAuth.instance.currentUser,
        ),

        // ✅ Theme Provider
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),

        // 🔒 Restaurant Scope
        ChangeNotifierProvider<RestaurantScope>(
          create: (_) => RestaurantScope(),
        ),

// 🍽️ Menu Service
        ProxyProvider<RestaurantScope, MenuService>(
          update: (_, scope, __) =>
              MenuService(restaurantId: scope.restaurantId),
        ),

// ➕ Addon Service
        ProxyProvider<RestaurantScope, AddonService>(
          update: (_, scope, __) =>
              AddonService(restaurantId: scope.restaurantId),
        ),

// 📂 Category Service
        ProxyProvider<RestaurantScope, CategoryService>(
          update: (_, scope, __) =>
              CategoryService(restaurantId: scope.restaurantId),
        ),
      ],
      child: const AppView(),
    );
  }
}
