import 'package:flutter/material.dart';
import 'widgets/menu_header.dart';
import 'widgets/menu_stats_section.dart';
import 'widgets/menu_management_grid.dart';

class MenuManagementScreen extends StatelessWidget {
  final String restaurantId;

  const MenuManagementScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MenuHeader(),
          const SizedBox(height: 28),
          MenuStatsSection(
            restaurantId: restaurantId,
          ),
          const SizedBox(height: 32),
          MenuManagementGrid(
            width: width,
            restaurantId: restaurantId,
          ),
        ],
      ),
    );
  }
}
