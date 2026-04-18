import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodfleet/models/restaurant_model.dart';
import 'package:foodfleet/providers/cart_providers.dart';
import 'package:foodfleet/screens/customers/screens/menu/cart/all_carts_screen.dart';
import 'package:foodfleet/screens/customers/screens/payments/delivery_fee.dart';
import 'package:foodfleet/screens/customers/widgets/restaurant_card.dart';
import 'package:provider/provider.dart';

class RestaurantsNearYouScreen extends StatefulWidget {
  final String selectedTown;
  final double? customerLat;
  final double? customerLng;

  const RestaurantsNearYouScreen({
    super.key,
    required this.selectedTown,
    this.customerLat,
    this.customerLng,
  });

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

    // ── FILTER BY TOWN ──
    if (widget.selectedTown.isNotEmpty) {
      result = result.where((r) {
        return r.town
                .toLowerCase()
                .contains(widget.selectedTown.toLowerCase()) ||
            widget.selectedTown.toLowerCase().contains(r.town.toLowerCase());
      }).toList();

      // If no restaurants in selected town, show all (fallback)
      if (result.isEmpty) result = all;
    }

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

    // ── SORT BY DISTANCE if customer coordinates available ──
    if (_selectedSort == 'Nearest' &&
        widget.customerLat != null &&
        widget.customerLng != null) {
      result.sort((a, b) {
        if (a.latitude == null || a.longitude == null) return 1;
        if (b.latitude == null || b.longitude == null) return -1;
        final distA = DeliveryFeeService.calculateDistanceKm(
          lat1: widget.customerLat!,
          lng1: widget.customerLng!,
          lat2: a.latitude!,
          lng2: a.longitude!,
        );
        final distB = DeliveryFeeService.calculateDistanceKm(
          lat1: widget.customerLat!,
          lng1: widget.customerLng!,
          lat2: b.latitude!,
          lng2: b.longitude!,
        );
        return distA.compareTo(distB);
      });
    } else if (_selectedSort == 'A-Z') {
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

  // ── GET DISTANCE STRING ──
  String? _getDistanceLabel(RestaurantModel restaurant) {
    if (widget.customerLat == null ||
        widget.customerLng == null ||
        restaurant.latitude == null ||
        restaurant.longitude == null) {
      return null;
    }

    final km = DeliveryFeeService.calculateDistanceKm(
      lat1: widget.customerLat!,
      lng1: widget.customerLng!,
      lat2: restaurant.latitude!,
      lng2: restaurant.longitude!,
    );

    return km < 1
        ? '${(km * 1000).toStringAsFixed(0)}m away'
        : '${km.toStringAsFixed(1)}km away';
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

    // Sort options — add "Nearest" if customer coords available
    final sortOptions = ['A-Z', 'Z-A'];
    if (widget.customerLat != null) sortOptions.insert(0, 'Nearest');

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──
            Container(
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
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Restaurants Near You',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.selectedTown.isNotEmpty)
                          Text(
                            '📍 ${widget.selectedTown}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AllCartsScreen()),
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
                                  color: Colors.red, shape: BoxShape.circle),
                              constraints: const BoxConstraints(
                                  minWidth: 16, minHeight: 16),
                              child: Text(
                                totalCartCount > 99 ? '99+' : '$totalCartCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
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
            ),

            // ── SEARCH + FILTERS ──
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
                              items: sortOptions,
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

            // ── RESTAURANT LIST ──
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
                        child: Text('No restaurants available'));
                  }

                  final all = snapshot.data!.docs
                      .map((doc) => RestaurantModel.fromFirestore(doc))
                      .toList();

                  final filtered = _filter(all);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_outlined,
                              size: 60, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No restaurants found in ${widget.selectedTown}',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different area',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: width > 600 ? 40 : 16,
                      vertical: 10,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final restaurant = filtered[index];
                      final distanceLabel = _getDistanceLabel(restaurant);
                      return RestaurantCard(
                        restaurant: restaurant,
                        distanceLabel: distanceLabel,
                      );
                    },
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

// ── SEARCH BAR ──
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
          hintText: 'Search restaurants or meals',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ── FILTER DROPDOWN ──
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
