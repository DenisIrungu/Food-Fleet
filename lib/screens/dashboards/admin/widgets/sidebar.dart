import 'package:flutter/material.dart';
import 'package:foodfleet/services/auth_service.dart';
import 'package:foodfleet/utils/routes.dart';

class Sidebar extends StatelessWidget {
  final ColorScheme colors;
  const Sidebar({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Container(
      width: 240,
      color: colors.secondary,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Restaurant',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          NavItem(Icons.dashboard, 'Dashboard', isActive: true),
          NavItem(Icons.receipt_long, 'Orders'),
          NavItem(Icons.menu_book, 'Menu'),
          NavItem(Icons.bar_chart, 'Earnings'),
          NavItem(Icons.person, 'Profile'),
          const Spacer(),
          InkWell(
            onTap: () async {
              await authService.signOut();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                LOGIN_ROUTE,
                (route) => false,
              );
            },
            child: NavItem(Icons.logout, 'Logout'),
          ),
        ],
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const NavItem(this.icon, this.label, {super.key, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: isActive ? Colors.white : Colors.white70),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
