import 'package:flutter/material.dart';
import 'package:foodfleet/models/restaurant_model.dart';
import 'package:foodfleet/models/user_model.dart';

class RestaurantDrawer extends StatelessWidget {
  final RestaurantModel restaurant;
  final UserModel userData;
  final ColorScheme colors;
  final int selectedIndex;
  final Function(int) onNavigate;

  const RestaurantDrawer({
    super.key,
    required this.restaurant,
    required this.userData,
    required this.colors,
    required this.selectedIndex,
    required this.onNavigate,
  });

  // Navigation configuration
  static const List<String> _titles = [
    "Dashboard",
    "Orders",
    "Manage Riders",
    "Menu",
    "Earnings",
    "Profile",
  ];

  static const List<IconData> _icons = [
    Icons.dashboard,
    Icons.receipt_long,
    Icons.person,
    Icons.menu_book,
    Icons.bar_chart,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: colors.secondary,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: BoxDecoration(color: colors.secondary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.restaurant, color: colors.onSecondary, size: 40),
                const SizedBox(height: 10),
                Text(
                  restaurant.name,
                  style: TextStyle(
                    color: colors.tertiary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  userData.email ?? 'No email',
                  style: TextStyle(
                    color: colors.tertiary.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Navigation Items
          for (int i = 0; i < _titles.length; i++)
            _buildDrawerItem(_icons[i], _titles[i], i),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final bool selected = selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? colors.onSecondary : colors.tertiary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? colors.onSecondary : colors.tertiary,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      onTap: () => onNavigate(index),
    );
  }
}
