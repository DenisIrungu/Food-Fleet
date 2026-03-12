import 'package:flutter/material.dart';
import 'menu_management_tile.dart';
import 'package:foodfleet/utils/routes.dart';

class MenuManagementGrid extends StatelessWidget {
  final double width;
  final String restaurantId;

  const MenuManagementGrid({
    super.key,
    required this.width,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    int crossAxisCount;

    if (width >= 1100) {
      crossAxisCount = 2;
    } else if (width >= 700) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 2.2,
      children: [
        MenuManagementTile(
          icon: Icons.folder_open,
          title: "Manage Categories",
          subtitle: "Create and organize food categories",
          buttonText: "View Categories",
          onTap: () {
            Navigator.pushNamed(
              context,
              MENU_DASHBOARD_ROUTE,
              arguments: restaurantId,
            );
          },
        ),
        MenuManagementTile(
          icon: Icons.restaurant_menu,
          title: "Manage Menu Items",
          subtitle: "Add, edit, and control menu items",
          buttonText: "View Items",
          onTap: () {
            Navigator.pushNamed(
              context,
              MENU_DASHBOARD_ROUTE,
              arguments: restaurantId,
            );
          },
        ),
        MenuManagementTile(
          icon: Icons.add_circle_outline,
          title: "Manage Add-ons",
          subtitle: "Create optional extras for items",
          buttonText: "View Add-ons",
          onTap: () {
            Navigator.pushNamed(
              context,
              MENU_DASHBOARD_ROUTE,
              arguments: restaurantId,
            );
          },
        ),
        MenuManagementTile(
          icon: Icons.layers,
          title: "Manage Addon Groups",
          subtitle: "Group add-ons and control selection rules",
          buttonText: "View Groups",
          onTap: () {
            Navigator.pushNamed(
              context,
              MENU_DASHBOARD_ROUTE,
              arguments: restaurantId,
            );
          },
        ),
      ],
    );
  }
}
