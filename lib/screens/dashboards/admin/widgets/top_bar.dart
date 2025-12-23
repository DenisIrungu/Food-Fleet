import 'package:flutter/material.dart';
import 'package:foodfleet/services/auth_service.dart';
import 'package:foodfleet/utils/routes.dart';

class TopBar extends StatelessWidget {
  final ColorScheme colors;
  const TopBar({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colors.secondary,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          const Text(
            "Mama Njeri's Kitchen",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          const ActiveBadge(),
          const SizedBox(width: 16),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
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
          const CircleAvatar(child: Icon(Icons.person)),
        ],
      ),
    );
  }
}

class ActiveBadge extends StatelessWidget {
  const ActiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Active',
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
      ),
    );
  }
}
