import 'package:flutter/material.dart';
import 'package:foodfleet/screens/dashboards/super_admin/settings.dart';
import 'dashboard_overview.dart';
import 'manage_restaurants.dart'; 

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    "Dashboard Overview",
    "Manage Restaurants (Admins)",
    "Manage Customers",
    "Settings",
  ];

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardOverview();
      case 1:
        return const ManageRestaurants(); 
      case 2:
        return const Center(child: Text("Manage Customers — Coming Soon"));
      case 3:
        return const SettingsScreen();
      default:
        return const DashboardOverview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.secondary,
        title: Text(
          _titles[_selectedIndex],
          style: TextStyle(color: colors.tertiary),
        ),
        iconTheme: IconThemeData(color: colors.tertiary),
      ),
      drawer: Drawer(
        backgroundColor: colors.secondary,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: colors.secondary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.admin_panel_settings, color: colors.onSecondary, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    "Super Admin",
                    style: TextStyle(
                      color: colors.tertiary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "foodfleet@admin.com",
                    style: TextStyle(color: colors.tertiary),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.dashboard, "Dashboard Overview", 0, colors),
            _buildDrawerItem(Icons.restaurant, "Manage Restaurants (Admins)", 1, colors),
            _buildDrawerItem(Icons.people, "Manage Customers", 2, colors),
            _buildDrawerItem(Icons.settings, "Settings", 3, colors),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _getSelectedScreen(),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index, ColorScheme colors) {
    final bool selected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon,
          color: selected ? colors.onSecondary : colors.tertiary),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? colors.onSecondary : colors.tertiary,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}
