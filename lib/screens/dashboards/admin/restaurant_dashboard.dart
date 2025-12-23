import 'package:flutter/material.dart';
import 'widgets/sidebar.dart';
import 'widgets/top_bar.dart';
import 'widgets/status_banner.dart';
import 'widgets/stats_grid.dart';
import 'widgets/quick_actions.dart';
import 'widgets/todays_summary.dart';
import 'widgets/recent_orders.dart';

class RestaurantDashboard extends StatelessWidget {
  const RestaurantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1000;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Row(
        children: [
          if (isDesktop) Sidebar(colors: colors),
          Expanded(
            child: Column(
              children: [
                TopBar(colors: colors),
                Expanded(
                  child: SingleChildScrollView(
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
