import 'package:flutter/material.dart';
import 'package:foodfleet/screens/dashboards/restaurant_admin/manage_menu/addon_group/addon_groups_screen.dart';
import 'package:foodfleet/screens/dashboards/restaurant_admin/manage_menu/addon_items/addon_item_screen.dart';
import 'package:foodfleet/screens/dashboards/restaurant_admin/manage_menu/categories/categories_screen.dart';
import 'package:foodfleet/screens/dashboards/restaurant_admin/manage_menu/menu_items/menu_items_screen.dart';

enum MenuTab { categories, items, addonItems, addonGroups }

class MenuDashboard extends StatefulWidget {
  final String restaurantId;
  final MenuTab initialTab;

  const MenuDashboard({
    super.key,
    required this.restaurantId,
    this.initialTab = MenuTab.categories,
  });

  @override
  State<MenuDashboard> createState() => _MenuDashboardState();
}

class _MenuDashboardState extends State<MenuDashboard> {
  late MenuTab _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Manage Menu'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ---------------------------
// TOP MENU TABS (CARDS)
// ---------------------------
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                // Responsive card width
                double cardWidth;
                if (width >= 1400) {
                  cardWidth = (width - 48) / 4; // 4 per row
                } else if (width >= 900) {
                  cardWidth = (width - 32) / 3; // 3 per row
                } else if (width >= 600) {
                  cardWidth = (width - 16) / 2; // 2 per row
                } else {
                  cardWidth = width; // 1 per row (mobile)
                }

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _MenuTabCard(
                        title: 'Categories',
                        subtitle: 'Organize menu sections',
                        icon: Icons.folder,
                        isActive: _selectedTab == MenuTab.categories,
                        onTap: () => _switchTab(MenuTab.categories),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _MenuTabCard(
                        title: 'Menu Items',
                        subtitle: 'Add & manage dishes',
                        icon: Icons.restaurant,
                        isActive: _selectedTab == MenuTab.items,
                        onTap: () => _switchTab(MenuTab.items),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _MenuTabCard(
                        title: 'Addon Items',
                        subtitle: 'Create addon options',
                        icon: Icons.add_shopping_cart,
                        isActive: _selectedTab == MenuTab.addonItems,
                        onTap: () => _switchTab(MenuTab.addonItems),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _MenuTabCard(
                        title: 'Addon Groups',
                        subtitle: 'Organize addon items',
                        icon: Icons.extension,
                        isActive: _selectedTab == MenuTab.addonGroups,
                        onTap: () => _switchTab(MenuTab.addonGroups),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const Divider(height: 1),

          // ---------------------------
          // ACTIVE TAB CONTENT
          // ---------------------------
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  void _switchTab(MenuTab tab) {
    setState(() => _selectedTab = tab);
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case MenuTab.categories:
        return const CategoriesScreen();
      case MenuTab.items:
        return const MenuItemsScreen();
      case MenuTab.addonItems:
        return AddonItemsScreen(restaurantId: widget.restaurantId);
      case MenuTab.addonGroups:
        return AddonGroupsScreen(restaurantId: widget.restaurantId);
    }
  }
}

// --------------------------------------------------
// TAB CARD WIDGET
// --------------------------------------------------
class _MenuTabCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _MenuTabCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: colors.tertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? colors.onPrimary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: colors.onPrimary.withOpacity(0.2),
                blurRadius: 8,
              ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 28, color: colors.onSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
