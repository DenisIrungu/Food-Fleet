import 'package:flutter/material.dart';
import 'package:foodfleet/services/auth_service.dart';
import 'package:foodfleet/utils/routes.dart';

class RestaurantDashboard extends StatelessWidget {
  const RestaurantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();

              if (!context.mounted) return;

              // 🔐 Clear navigation stack and go to login
              Navigator.pushNamedAndRemoveUntil(
                context,
                LOGIN_ROUTE,
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: colors.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.restaurant,
                size: 70,
                color: colors.tertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome, Restaurant!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Manage your menu and orders here',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onSurface.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
