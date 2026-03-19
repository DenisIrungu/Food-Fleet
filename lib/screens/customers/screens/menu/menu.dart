import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodfleet/models/category_model.dart';
import 'package:foodfleet/models/menu_item_model.dart';
import 'package:foodfleet/models/restaurant_model.dart';
import 'package:foodfleet/providers/cart_providers.dart';
import 'package:foodfleet/screens/customers/screens/menu/foodpage.dart';
import 'package:provider/provider.dart';

class MenuPage extends StatefulWidget {
  final RestaurantModel restaurant;
  final VoidCallback? onCartTap;

  const MenuPage({super.key, required this.restaurant, this.onCartTap});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  String _searchQuery = '';
  List<CategoryModel> _categories = [];
  bool _categoriesLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _updateTabController(List<CategoryModel> categories) {
    final totalTabs = categories.length + 1;
    if (_tabController.length != totalTabs) {
      _tabController.dispose();
      _tabController = TabController(length: totalTabs, vsync: this);
    }
    _categories = categories;
    _categoriesLoaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final cartCount =
        context.watch<CartProvider>().itemCountFor(widget.restaurant.id);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF0F2A12),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.restaurant.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.restaurant.cuisineTypes.isNotEmpty
                  ? widget.restaurant.cuisineTypes.join(', ')
                  : 'Various cuisines',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: Colors.white, size: 26),
                onPressed: widget.onCartTap,
              ),
              if (cartCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      cartCount > 99 ? '99+' : '$cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('restaurants')
              .doc(widget.restaurant.id)
              .collection('categories')
              .where('isActive', isEqualTo: true)
              .orderBy('position')
              .snapshots(),
          builder: (context, categorySnapshot) {
            if (categorySnapshot.connectionState == ConnectionState.waiting &&
                !_categoriesLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            final categories = categorySnapshot.hasData
                ? categorySnapshot.data!.docs
                    .map((d) => CategoryModel.fromFirestore(d))
                    .where((c) => !c.isDefault)
                    .toList()
                : <CategoryModel>[];

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final totalTabs = categories.length + 1;
                if (_tabController.length != totalTabs) {
                  setState(() => _updateTabController(categories));
                } else {
                  _categories = categories;
                  _categoriesLoaded = true;
                }
              }
            });

            final tabLabels = ['All', ...categories.map((c) => c.name)];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),

                // ── SEARCH ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search menu...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── CATEGORY TABS ──
                if (_tabController.length == tabLabels.length)
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.center,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black54,
                    indicator: BoxDecoration(
                      color: const Color(0xFF0F2A12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    splashBorderRadius: BorderRadius.circular(30),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    tabs: tabLabels.map((label) => Tab(text: label)).toList(),
                  ),

                const SizedBox(height: 12),

                // ── MENU ITEMS ──
                Expanded(
                  child: _tabController.length != tabLabels.length
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: tabLabels.map((label) {
                            if (label == 'All') {
                              return _AllItemsTab(
                                restaurant: widget.restaurant,
                                categories: categories,
                                searchQuery: _searchQuery,
                              );
                            }
                            final cat =
                                categories.firstWhere((c) => c.name == label);
                            return _CategoryItemsTab(
                              restaurant: widget.restaurant,
                              category: cat,
                              searchQuery: _searchQuery,
                            );
                          }).toList(),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ALL ITEMS TAB — shows each category as a section
// ─────────────────────────────────────────────

class _AllItemsTab extends StatelessWidget {
  final RestaurantModel restaurant;
  final List<CategoryModel> categories;
  final String searchQuery;

  const _AllItemsTab({
    required this.restaurant,
    required this.categories,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: categories.length,
      itemBuilder: (context, index) => _CategorySection(
        restaurant: restaurant,
        category: categories[index],
        searchQuery: searchQuery,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CATEGORY SECTION — used in All tab
// ─────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final RestaurantModel restaurant;
  final CategoryModel category;
  final String searchQuery;

  const _CategorySection({
    required this.restaurant,
    required this.category,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurant.id)
          .collection('categories')
          .doc(category.id)
          .collection('menu_items')
          .orderBy('position')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        var items = snapshot.data!.docs
            .map((d) => MenuItemModel.fromFirestore(d))
            .where((item) => !item.isAddon && item.isAvailable)
            .toList();

        if (searchQuery.isNotEmpty) {
          items = items
              .where((i) => i.name.toLowerCase().contains(searchQuery))
              .toList();
        }

        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── CATEGORY TITLE ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2A12),
                ),
              ),
            ),

            // ── HORIZONTAL SCROLL ──
            SizedBox(
              height: 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (context, index) => _MenuCard(
                  item: items[index],
                  restaurant: restaurant,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// CATEGORY ITEMS TAB — single category full view
// ─────────────────────────────────────────────

class _CategoryItemsTab extends StatelessWidget {
  final RestaurantModel restaurant;
  final CategoryModel category;
  final String searchQuery;

  const _CategoryItemsTab({
    required this.restaurant,
    required this.category,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurant.id)
          .collection('categories')
          .doc(category.id)
          .collection('menu_items')
          .orderBy('position')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No items in this category'));
        }

        var items = snapshot.data!.docs
            .map((d) => MenuItemModel.fromFirestore(d))
            .where((item) => !item.isAddon && item.isAvailable)
            .toList();

        if (searchQuery.isNotEmpty) {
          items = items
              .where((i) => i.name.toLowerCase().contains(searchQuery))
              .toList();
        }

        if (items.isEmpty) {
          return const Center(child: Text('No items match your search'));
        }

        // ── WRAP LAYOUT (same card, wraps to next line) ──
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: items
                .map((item) => _MenuCard(
                      item: item,
                      restaurant: restaurant,
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// MENU CARD — matches TopFoodCard style exactly
// ─────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final MenuItemModel item;
  final RestaurantModel restaurant;

  const _MenuCard({required this.item, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FoodPage(
            food: item,
            restaurantId: restaurant.id,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── IMAGE ──
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      width: 140,
                      height: 120,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _placeholder();
                      },
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(height: 8),
            // ── NAME ──
            SizedBox(
              width: 140,
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // ── PRICE ──
            Text(
              'Ksh ${item.price.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 140,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.fastfood, size: 36, color: Colors.grey),
        ),
      );
}
