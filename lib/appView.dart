import 'package:flutter/material.dart';
import 'package:foodfleet/Theme/theme_provider.dart';
import 'package:foodfleet/screens/splashscreens/splashscreen1.dart';
import 'package:foodfleet/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/routes.dart';
import 'utils/constants.dart';
import 'models/user_model.dart';
// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboards/super_admin/super_admin_dashboard.dart';

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    // 👇 Get the theme provider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: APP_NAME,
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData, 
      
      // Initial route
      initialRoute: SPLASH_ROUTE,
      
      // Define all routes
      routes: {
        SPLASH_ROUTE: (context) => const AuthWrapper(),
        LOGIN_ROUTE: (context) => const LoginScreen(),
         REGISTER_ROUTE: (context) => SignUp(
  onTap: () {
    Navigator.pushNamed(context, LOGIN_ROUTE); // Navigate to login screen when tapped
  },
),

        // CHANGE_PASSWORD_ROUTE: (context) => const ChangePasswordScreen(),
         SUPER_ADMIN_DASHBOARD_ROUTE: (context) => const SuperAdminDashboard(),
        // RESTAURANT_DASHBOARD_ROUTE: (context) => const RestaurantDashboard(),
        // RIDER_DASHBOARD_ROUTE: (context) => const RiderDashboard(),
        // CUSTOMER_DASHBOARD_ROUTE: (context) => const CustomerDashboard(),
      },
    );
  }
}

// Auth Wrapper - Decides what to show based on auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseService = context.read<DatabaseService>();
    final firebaseUser = context.watch<User?>();

    // If no user is logged in, show splash screen
    if (firebaseUser == null) {
      return  SplashScreen();
    }

    // User is logged in, fetch their data and navigate to appropriate dashboard
    return FutureBuilder<UserModel?>(
      future: databaseService.getUserData(firebaseUser.uid),
      builder: (context, snapshot) {
        // Loading state - show simple loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        }

        // Error state or no data - back to splash
        if (snapshot.hasError || !snapshot.hasData) {
          return const SplashScreen();
        }

        final user = snapshot.data!;

        // Check if first login - force password change
        // if (user.firstLogin) {
        //   return const ChangePasswordScreen();
        // }

        // Navigate based on role
        return _getDashboardForRole(user.role);
      },
    );
  }

  // Get dashboard widget based on user role
  Widget _getDashboardForRole(String role) {
    switch (role) {
      case ROLE_SUPER_ADMIN:
        return const SuperAdminDashboard();
      // case ROLE_RESTAURANT_ADMIN:
      //   return const RestaurantDashboard();
      // case ROLE_RIDER:
      //   return const RiderDashboard();
      // case ROLE_CUSTOMER:
      //   return const CustomerDashboard();
      default:
        return const SplashScreen();
    }
  }
}
