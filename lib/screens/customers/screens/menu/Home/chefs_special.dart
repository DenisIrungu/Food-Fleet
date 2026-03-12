import 'package:flutter/material.dart';
import 'package:foodfleet/models/menu_item_model.dart';
import 'package:foodfleet/screens/customers/screens/menu/foodpage.dart';

// ================= CHEF'S SPECIAL SECTION =================
class ChefsSpecialSection extends StatelessWidget {
  final Stream<List<MenuItemModel>> stream;
  final String restaurantId;

  const ChefsSpecialSection({
    super.key,
    required this.stream,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MenuItemModel>>(
      stream: stream,
      builder: (context, snapshot) {
        final items = snapshot.data;
        if (items == null || items.isEmpty) return const ChefsSpecialSkeleton();
        return ChefsSpecialCard(item: items.first, restaurantId: restaurantId);
      },
    );
  }
}

// ================= CHEF'S SPECIAL CARD =================
class ChefsSpecialCard extends StatelessWidget {
  final MenuItemModel item;
  final String restaurantId;

  const ChefsSpecialCard({
    super.key,
    required this.item,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F5F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.restaurant, size: 14, color: Color(0xFF0F2A12)),
                    SizedBox(width: 5),
                    Text(
                      "Chef's Recommendation",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F2A12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F2A12),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Ksh ${item.price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF0F2A12),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FoodPage(
                          food: item,
                          restaurantId: restaurantId,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2A12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    "Order Now",
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // ── FOOD IMAGE ──
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoodPage(
                      food: item,
                      restaurantId: restaurantId,
                    ),
                  ),
                );
              },
              child: SizedBox(
                height: 120,
                width: 120,
                child: ClipOval(
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(color: Colors.grey.shade200);
                          },
                          errorBuilder: (_, __, ___) => _imageFallback(),
                        )
                      : _imageFallback(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() => Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(Icons.fastfood, size: 40, color: Colors.grey),
        ),
      );
}

// ================= CHEF'S SPECIAL SKELETON =================
class ChefsSpecialSkeleton extends StatelessWidget {
  const ChefsSpecialSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F5F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(width: 140, height: 12),
                const SizedBox(height: 14),
                _shimmerBox(width: double.infinity, height: 20),
                const SizedBox(height: 8),
                _shimmerBox(width: 120, height: 20),
                const SizedBox(height: 10),
                _shimmerBox(width: 80, height: 16),
                const SizedBox(height: 20),
                _shimmerBox(width: 110, height: 38, radius: 20),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(
          {required double width, required double height, double radius = 8}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
