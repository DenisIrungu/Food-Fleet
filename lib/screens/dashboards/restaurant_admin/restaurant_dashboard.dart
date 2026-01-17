import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodfleet/models/restaurant_model.dart';
import 'package:foodfleet/models/user_model.dart';
import 'package:foodfleet/services/auth_service.dart';
import 'package:foodfleet/services/database_service.dart';
import 'package:foodfleet/utils/routes.dart';
import 'restaurant_widgets/active_badge.dart';
import 'restaurant_widgets/restaurant_drawer.dart';
import 'restaurant_widgets/status_banner.dart';
import 'restaurant_widgets/stats_grid.dart';
import 'restaurant_widgets/quick_actions.dart';
import 'restaurant_widgets/todays_summary.dart';
import 'restaurant_widgets/recent_orders.dart';
import 'restaurant_widgets/profile_picture.dart';

class RestaurantDashboard extends StatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    "Dashboard",
    "Orders",
    "Manage Riders",
    "Menu",
    "Earnings",
    "Profile",
  ];

  Widget _getSelectedScreen(double width) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardOverview(width);
      case 1:
        return const Center(child: Text("Orders — Coming Soon"));
      case 2:
        return const Center(child: Text("Manage Riders — Coming Soon"));
      case 3:
        return const Center(child: Text("Menu — Coming Soon"));
      case 4:
        return const Center(child: Text("Earnings — Coming Soon"));
      case 5:
        return const Center(child: Text("Profile — Coming Soon"));
      default:
        return _buildDashboardOverview(width);
    }
  }

  Widget _buildDashboardOverview(double width) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBanner(colors: colors),
          const SizedBox(height: 20),
          StatsGrid(width: width),
          const SizedBox(height: 24),
          const QuickActions(),
          const SizedBox(height: 24),
          const TodaysSummary(),
          const SizedBox(height: 24),
          RecentOrders(colors: colors),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final authService = AuthService();
    final db = DatabaseService();
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: db.getUserDataStream(user.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError && kDebugMode) {
          print("❌ User stream error: ${userSnapshot.error}");
        }

        if (!userSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = userSnapshot.data!;

        if (userData.restaurantId == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 48),
                  SizedBox(height: 16),
                  Text("Restaurant not linked"),
                ],
              ),
            ),
          );
        }

        return StreamBuilder<RestaurantModel?>(
          stream: db.streamRestaurantById(userData.restaurantId!),
          builder: (context, restaurantSnapshot) {
            if (restaurantSnapshot.hasError && kDebugMode) {
              print("❌ Restaurant stream error: ${restaurantSnapshot.error}");
            }

            if (!restaurantSnapshot.hasData) {
              return Scaffold(
                appBar: AppBar(
                  backgroundColor: colors.secondary,
                  title: Text(
                    _titles[_selectedIndex],
                    style: TextStyle(color: colors.tertiary),
                  ),
                ),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            final restaurant = restaurantSnapshot.data!;

            return Scaffold(
              backgroundColor: colors.surface,
              appBar: AppBar(
                backgroundColor: colors.secondary,
                title: Text(
                  _titles[_selectedIndex],
                  style: TextStyle(color: colors.tertiary),
                ),
                iconTheme: IconThemeData(color: colors.tertiary),
                actions: [
                  ActiveBadge(status: restaurant.status),
                  const SizedBox(width: 16),
                  IconButton(
                    tooltip: 'Logout',
                    icon: Icon(Icons.logout, color: colors.tertiary),
                    onPressed: () async {
                      await authService.signOut();
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        LOGIN_ROUTE,
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: ProfilePictureWidget(
                      userData: userData,
                      restaurant: restaurant,
                      colors: colors,
                    ),
                  ),
                ],
              ),
              drawer: RestaurantDrawer(
                restaurant: restaurant,
                userData: userData,
                colors: colors,
                selectedIndex: _selectedIndex,
                onNavigate: (index) {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
              ),
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _getSelectedScreen(width),
              ),
            );
          },
        );
      },
    );
  }
}
