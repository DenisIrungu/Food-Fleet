import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodfleet/models/restaurant_model.dart';
import 'package:foodfleet/providers/cart_providers.dart';
import 'package:foodfleet/screens/customers/screens/menu/cart/all_carts_screen.dart';
import 'package:foodfleet/screens/customers/widgets/restaurant_card.dart';
import 'package:provider/provider.dart';

class RestaurantsNearYouScreen extends StatefulWidget {
  const RestaurantsNearYouScreen({super.key});

  @override
  State<RestaurantsNearYouScreen> createState() =>
      _RestaurantsNearYouScreenState();
}

class _RestaurantsNearYouScreenState extends State<RestaurantsNearYouScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCuisine = 'All';
  String _selectedStatus = 'All';
  String _selectedSort = 'A-Z';

  List<RestaurantModel> _filter(List<RestaurantModel> all) {
    List<RestaurantModel> result = all;

    if (_searchQuery.isNotEmpty) {
      result = result.where((r) {
        return r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.cuisineTypes.any(
                (c) => c.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }

    if (_selectedCuisine != 'All') {
      result = result
          .where((r) => r.cuisineTypes.contains(_selectedCuisine))
          .toList();
    }

    if (_selectedStatus != 'All') {
      result = result.where((r) => r.status == _selectedStatus).toList();
    }

    if (_selectedSort == 'A-Z') {
      result.sort((a, b) => a.name.compareTo(b.name));
    } else if (_selectedSort == 'Z-A') {
      result.sort((a, b) => b.name.compareTo(a.name));
    }

    return result;
  }

  List<String> _extractCuisines(List<RestaurantModel> restaurants) {
    final all = restaurants.expand((r) => r.cuisineTypes).toSet().toList();
    all.sort();
    return ['All', ...all];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final totalCartCount = context.watch<CartProvider>().totalItemCount;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            /// ================= HEADER =================
            _Header(width: width, totalCartCount: totalCartCount),

            /// ================= SEARCH + FILTERS =================
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width > 600 ? 40 : 16,
                vertical: 14,
              ),
              child: Column(
                children: [
                  _SearchBar(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('restaurants')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final cuisines = snapshot.hasData
                          ? _extractCuisines(snapshot.data!.docs
                              .map((d) => RestaurantModel.fromFirestore(d))
                              .toList())
                          : ['All'];

                      return Row(
                        children: [
                          Expanded(
                            child: _FilterDropdown(
                              label: 'Cuisine',
                              value: _selectedCuisine,
                              items: cuisines,
                              onChanged: (val) =>
                                  setState(() => _selectedCuisine = val!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _FilterDropdown(
                              label: 'Status',
                              value: _selectedStatus,
                              items: const ['All', 'active', 'inactive'],
                              onChanged: (val) =>
                                  setState(() => _selectedStatus = val!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _FilterDropdown(
                              label: 'Sort',
                              value: _selectedSort,
                              items: const ['A-Z', 'Z-A'],
                              onChanged: (val) =>
                                  setState(() => _selectedSort = val!),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            /// ================= RESTAURANT LIST =================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('restaurants')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text("No restaurants available"));
                  }

                  final all = snapshot.data!.docs
                      .map((doc) => RestaurantModel.fromFirestore(doc))
                      .toList();

                  final filtered = _filter(all);

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text("No restaurants match your search"),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: width > 600 ? 40 : 16,
                      vertical: 10,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) =>
                        RestaurantCard(restaurant: filtered[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= HEADER =================
class _Header extends StatelessWidget {
  final double width;
  final int totalCartCount;

  const _Header({required this.width, required this.totalCartCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width > 600 ? 40 : 16,
        vertical: 18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2A12), Color(0xFF0F2A15)],
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "Available Restaurants",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          // ── CART ICON WITH BADGE ──
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AllCartsScreen(),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.shopping_cart, color: Colors.white),
                ),
                if (totalCartCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        totalCartCount > 99 ? '99+' : '$totalCartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 14),
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ================= SEARCH BAR =================
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: "Search restaurants or meals",
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ================= FILTER DROPDOWN =================
class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
