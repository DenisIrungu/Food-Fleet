import 'package:flutter/material.dart';
import 'package:foodfleet/Theme/theme_provider.dart';
import 'package:foodfleet/screens/dashboards/restaurant_admin/manage_menu/addons/addon_groups_screen.dart';
import 'package:foodfleet/screens/dashboards/restaurant_admin/manage_menu/categories/categories_screen.dart';
import 'package:foodfleet/screens/dashboards/restaurant_admin/manage_menu/menu_dashboard.dart';
import 'package:foodfleet/screens/dashboards/restaurant_admin/manage_menu/menu_items/menu_items_screen.dart';
import 'package:foodfleet/screens/dashboards/restaurant_admin/restaurant_dashboard.dart';
import 'package:foodfleet/screens/dashboards/super_admin/change_password.dart';
import 'package:foodfleet/screens/dashboards/super_admin/create_admin.dart';
import 'package:foodfleet/screens/splashscreens/splashscreen1.dart';
import 'package:foodfleet/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/routes.dart';
import 'utils/constants.dart';
import 'models/user_model.dart';
import 'package:foodfleet/providers/restaurant_scope_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboards/super_admin/super_admin_dashboard.dart';

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: APP_NAME,
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      initialRoute: SPLASH_ROUTE,
      routes: {
        // ===============================
        // AUTH & CORE
        // ===============================
        SPLASH_ROUTE: (context) => const AuthWrapper(),
        LOGIN_ROUTE: (context) => const LoginScreen(),
        REGISTER_ROUTE: (context) => SignUp(
              onTap: () {
                Navigator.pushNamed(context, LOGIN_ROUTE);
              },
            ),
        CHANGE_PASSWORD_ROUTE: (context) => const ChangePasswordScreen(),

        // ===============================
        // DASHBOARDS
        // ===============================
        SUPER_ADMIN_DASHBOARD_ROUTE: (context) => const SuperAdminDashboard(),
        CREATE_ADMIN: (context) => const CreateAdmin(),
        RESTAURANT_DASHBOARD_ROUTE: (context) => const RestaurantDashboard(),

        // ===============================
        // ✅ MENU MANAGEMENT (NEW)
        // ===============================
        MENU_DASHBOARD_ROUTE: (context) => const MenuDashboard(),
        MANAGE_CATEGORIES_ROUTE: (context) => const CategoriesScreen(),
        MANAGE_MENU_ITEMS_ROUTE: (context) => const MenuItemsScreen(),
        MANAGE_ADDONS_ROUTE: (context) => const AddonGroupsScreen(),
        
      },
    );
  }
}

// ======================================================
// Auth Wrapper
// ======================================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseService = context.read<DatabaseService>();
    final firebaseUser = context.watch<User?>();

    if (firebaseUser == null) {
      return const SplashScreen();
    }

    return FutureBuilder<UserModel?>(
      future: databaseService.getUserData(firebaseUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SplashScreen();
        }

        final user = snapshot.data!;

        // 🔒 SET RESTAURANT SCOPE
        if (user.role == ROLE_RESTAURANT_ADMIN &&
            user.restaurantId != null &&
            user.restaurantId!.isNotEmpty) {
          context.read<RestaurantScope>().setRestaurant(user.restaurantId!);
        }

        if (user.role == ROLE_RESTAURANT_ADMIN && user.firstLogin) {
          return const ChangePasswordScreen();
        }

        return _getDashboardForRole(user.role);
      },
    );
  }

  Widget _getDashboardForRole(String role) {
    switch (role) {
      case ROLE_SUPER_ADMIN:
        return const SuperAdminDashboard();
      case ROLE_RESTAURANT_ADMIN:
        return const RestaurantDashboard();
      default:
        return const SplashScreen();
    }
  }
}
