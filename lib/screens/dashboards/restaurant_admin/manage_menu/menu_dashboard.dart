import 'package:flutter/material.dart';
import 'package:foodfleet/screens/dashboards/restaurant_admin/manage_menu/addons/addon_groups_screen.dart';
import 'package:foodfleet/screens/dashboards/restaurant_admin/manage_menu/categories/categories_screen.dart';
import 'package:foodfleet/screens/dashboards/restaurant_admin/manage_menu/menu_items/menu_items_screen.dart';

enum MenuTab { categories, items, addons }

class MenuDashboard extends StatefulWidget {
  final MenuTab initialTab;

  const MenuDashboard({
    super.key,
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
            child: GridView.count(
              crossAxisCount: isDesktop ? 3 : 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isDesktop ? 3.5 : 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _MenuTabCard(
                  title: 'Categories',
                  subtitle: 'Organize menu sections',
                  icon: Icons.folder,
                  isActive: _selectedTab == MenuTab.categories,
                  onTap: () => _switchTab(MenuTab.categories),
                ),
                _MenuTabCard(
                  title: 'Menu Items',
                  subtitle: 'Add & manage dishes',
                  icon: Icons.restaurant,
                  isActive: _selectedTab == MenuTab.items,
                  onTap: () => _switchTab(MenuTab.items),
                ),
                _MenuTabCard(
                  title: 'Add-ons',
                  subtitle: 'Create addon groups',
                  icon: Icons.add_circle_outline,
                  isActive: _selectedTab == MenuTab.addons,
                  onTap: () => _switchTab(MenuTab.addons),
                ),
              ],
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
      case MenuTab.addons:
        return const AddonGroupsScreen();
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
            Column(
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
