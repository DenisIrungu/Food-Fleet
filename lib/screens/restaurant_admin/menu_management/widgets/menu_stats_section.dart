import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:foodfleet/models/addon_group_model.dart';
import 'package:foodfleet/models/category_model.dart';
import 'package:foodfleet/models/menu_item_model.dart';
import 'package:foodfleet/services/addon_service.dart';
import 'package:foodfleet/services/menu_service.dart';
import 'menu_stat_card.dart';

class MenuStatsSection extends StatelessWidget {
  final String restaurantId;

  const MenuStatsSection({
    super.key,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final menuService = MenuService(restaurantId: restaurantId);
    final addonService = AddonService(restaurantId: restaurantId);

    int crossAxisCount;
    if (width >= 1100) {
      crossAxisCount = 5;
    } else if (width >= 800) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    return StreamBuilder<List<CategoryModel>>(
      stream: menuService.streamCategories(onlyActive: false),
      builder: (context, categorySnapshot) {
        final categories = categorySnapshot.data ?? [];

        final menuItemCountStream =
            _combineMenuItemStreams(categories, restaurantId);

        return StreamBuilder<int>(
          stream: menuItemCountStream,
          builder: (context, menuItemSnapshot) {
            final menuItemCount = menuItemSnapshot.data ?? 0;

            return StreamBuilder<List<MenuItemModel>>(
              stream: addonService.streamAllAddonItemsForAdmin(),
              builder: (context, addonItemSnapshot) {
                final addonItems = addonItemSnapshot.data ?? [];

                return StreamBuilder<List<AddonGroupModel>>(
                  stream: addonService.streamAddonGroupsForAdmin(),
                  builder: (context, addonGroupSnapshot) {
                    final addonGroups = addonGroupSnapshot.data ?? [];

                    final outOfStockCount = addonItems
                        .where((item) => item.isAvailable == false)
                        .length;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.4,
                      children: [
                        MenuStatCard(
                          title: "Categories",
                          value: categories.length.toString(),
                          icon: Icons.folder,
                        ),
                        MenuStatCard(
                          title: "Menu Items",
                          value: menuItemCount.toString(),
                          icon: Icons.restaurant_menu,
                        ),
                        MenuStatCard(
                          title: "Add-ons",
                          value: addonItems.length.toString(),
                          icon: Icons.add_circle_outline,
                        ),
                        MenuStatCard(
                          title: "Addon Groups",
                          value: addonGroups.length.toString(),
                          icon: Icons.layers,
                        ),
                        MenuStatCard(
                          title: "Out of Stock",
                          value: outOfStockCount.toString(),
                          icon: Icons.warning_amber_rounded,
                          isAlert: outOfStockCount > 0,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // 🔥 Combine all category menu item streams
  Stream<int> _combineMenuItemStreams(
      List<CategoryModel> categories, String restaurantId) {
    if (categories.isEmpty) {
      return Stream.value(0);
    }

    final menuService = MenuService(restaurantId: restaurantId);

    final streams = categories.map((category) {
      return menuService
          .streamMenuItemsByCategory(
            categoryId: category.id,
            isAdmin: true,
          )
          .map((items) => items.length);
    }).toList();

    return StreamZip(streams).map(
      (counts) => counts.fold<int>(0, (sum, count) => sum + count),
    );
  }
}
