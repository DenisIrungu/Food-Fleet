import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodfleet/models/restaurant_model.dart';
import 'package:foodfleet/providers/cart_providers.dart';
import 'package:foodfleet/screens/customers/screens/menu/cart.dart';
import 'package:provider/provider.dart';

class AllCartsScreen extends StatefulWidget {
  const AllCartsScreen({super.key});

  @override
  State<AllCartsScreen> createState() => _AllCartsScreenState();
}

class _AllCartsScreenState extends State<AllCartsScreen> {
  /// restaurantId → RestaurantModel
  final Map<String, RestaurantModel> _restaurants = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    final cart = context.read<CartProvider>();
    final activeIds = cart.activeRestaurantIds;

    if (activeIds.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final futures = activeIds.map((id) async {
        final doc = await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(id)
            .get();
        if (!doc.exists) return null;
        return RestaurantModel.fromFirestore(doc);
      });

      final results =
          (await Future.wait(futures)).whereType<RestaurantModel>().toList();

      if (mounted) {
        setState(() {
          for (final r in results) {
            _restaurants[r.id] = r;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final activeIds = cart.activeRestaurantIds;

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF0F2A12),
            foregroundColor: Colors.white,
            centerTitle: true,
            title: const Text(
              'Your Carts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : activeIds.isEmpty
                  ? _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: activeIds.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final restaurantId = activeIds[index];
                        final restaurant = _restaurants[restaurantId];
                        final itemCount = cart.itemCountFor(restaurantId);
                        final total = cart.totalPriceFor(restaurantId);

                        return _CartRestaurantCard(
                          restaurant: restaurant,
                          restaurantId: restaurantId,
                          itemCount: itemCount,
                          total: total,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CartScreen(
                                  restaurantId: restaurantId,
                                  restaurantName:
                                      restaurant?.name ?? 'Restaurant',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// CART RESTAURANT CARD
// ─────────────────────────────────────────────

class _CartRestaurantCard extends StatelessWidget {
  final RestaurantModel? restaurant;
  final String restaurantId;
  final int itemCount;
  final double total;
  final VoidCallback onTap;

  const _CartRestaurantCard({
    required this.restaurant,
    required this.restaurantId,
    required this.itemCount,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── RESTAURANT IMAGE ──
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: restaurant?.imageUrl != null &&
                      restaurant!.imageUrl!.isNotEmpty
                  ? Image.network(
                      restaurant!.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),

            const SizedBox(width: 14),

            // ── DETAILS ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant?.name ?? 'Restaurant',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2A12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ksh ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F2A12),
                    ),
                  ),
                ],
              ),
            ),

            // ── ARROW ──
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.restaurant, color: Colors.grey),
      );
}

// ─────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No active carts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items from a restaurant to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
