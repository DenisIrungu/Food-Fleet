import 'package:flutter/material.dart';
import 'package:foodfleet/models/category_model.dart';
import 'package:foodfleet/models/menu_item_model.dart';
import 'package:foodfleet/providers/restaurant_scope_provider.dart';
import 'package:foodfleet/screens/dashboards/restaurant_admin/manage_menu/menu_items/menu_items_form.dart';
import 'package:foodfleet/services/menu_service.dart';
import 'package:provider/provider.dart';

class MenuItemsScreen extends StatefulWidget {
  const MenuItemsScreen({super.key});

  @override
  State<MenuItemsScreen> createState() => _MenuItemsScreenState();
}

class _MenuItemsScreenState extends State<MenuItemsScreen> {
  CategoryModel? _selectedCategory;
  bool _isAdmin = true;
  MenuService? _menuService;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize MenuService only once
    if (!_initialized) {
      final restaurantId = context.read<RestaurantScope>().restaurantId;
      _menuService = MenuService(restaurantId: restaurantId);
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Wait for MenuService to be initialized
    if (_menuService == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Items'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _selectedCategory == null
                  ? null
                  : () => _openMenuItemForm(context),
              icon: Icon(Icons.add, color: colors.onPrimary),
              label: const Text('Add Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2A12),
                foregroundColor: colors.onPrimary,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<CategoryModel>>(
        future: _menuService!.getCategories(onlyActive: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return const Center(
              child: Text('No categories found. Create a category first.'),
            );
          }

          // Default to first category if none selected
          _selectedCategory ??= categories.first;

          return Column(
            children: [
              const SizedBox(height: 16),
              _CategoryFilter(
                categories: categories,
                selected: _selectedCategory!,
                onChanged: (cat) => setState(() => _selectedCategory = cat),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _selectedCategory == null
                    ? const Center(child: Text('Select a category'))
                    : StreamBuilder<List<MenuItemModel>>(
                        stream: _menuService!.streamMenuItemsByCategory(
                          categoryId: _selectedCategory!.id,
                          isAdmin: _isAdmin,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            debugPrint('Stream error: ${snapshot.error}');
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          final menuItems = snapshot.data ?? [];

                          if (menuItems.isEmpty) return const _EmptyState();

                          return ReorderableListView.builder(
                            itemCount: menuItems.length,
                            onReorder: (oldIndex, newIndex) async {
                              if (newIndex > oldIndex) newIndex--;
                              setState(() {
                                final item = menuItems.removeAt(oldIndex);
                                menuItems.insert(newIndex, item);
                              });

                              final positions = {
                                for (int i = 0; i < menuItems.length; i++)
                                  menuItems[i].id: i
                              };
                              await _menuService!.updateMenuItemPositions(
                                categoryId: _selectedCategory!.id,
                                positions: positions,
                              );
                            },
                            itemBuilder: (context, index) {
                              final item = menuItems[index];
                              return Card(
                                key: ValueKey(item.id),
                                color: colors.tertiary,
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        colors.surfaceContainerHighest,
                                    backgroundImage: item.imageUrl.isNotEmpty
                                        ? NetworkImage(item.imageUrl)
                                        : null,
                                    child: item.imageUrl.isEmpty
                                        ? const Icon(Icons.restaurant_menu)
                                        : null,
                                    onBackgroundImageError:
                                        item.imageUrl.isNotEmpty
                                            ? (exception, stackTrace) {
                                                debugPrint(
                                                    'Image failed to load for ${item.name}: $exception');
                                              }
                                            : null,
                                  ),
                                  title: Text(item.name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: colors.secondary)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (item.description != null)
                                        Text(item.description!,
                                            style: TextStyle(
                                                color: colors.onSecondary)),
                                      const SizedBox(height: 4),
                                      Text(
                                        'KES ${item.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: colors.primary),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: item.isAvailable,
                                        activeColor: colors.onPrimary,
                                        onChanged: (value) async {
                                          await _menuService!
                                              .setMenuItemAvailability(
                                            categoryId: _selectedCategory!.id,
                                            itemId: item.id,
                                            isAvailable: value,
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _openMenuItemForm(
                                          context,
                                          existingItem: item,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.redAccent),
                                        onPressed: () => _confirmDelete(item),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openMenuItemForm(BuildContext context, {MenuItemModel? existingItem}) {
    showDialog(
      context: context,
      builder: (_) => Provider.value(
        value: _menuService,
        child: Material(
          child: MenuItemForm(
            existingItem: existingItem,
            initialCategory: _selectedCategory,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(MenuItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _menuService!.deleteMenuItem(
          categoryId: _selectedCategory!.id,
          item: item,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted menu item: ${item.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting menu item: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete menu item: ${item.name}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }
}

class _CategoryFilter extends StatelessWidget {
  final List<CategoryModel> categories;
  final CategoryModel selected;
  final ValueChanged<CategoryModel> onChanged;

  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: categories.map((category) {
          final isSelected = category.id == selected.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category.name),
              selected: isSelected,
              onSelected: (_) => onChanged(category),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu_outlined,
              size: 64, color: colors.onSecondary),
          const SizedBox(height: 16),
          Text(
            'No menu items found',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.secondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items for this category to build your menu',
            style: TextStyle(color: colors.onSecondary),
          ),
        ],
      ),
    );
  }
}
