import 'package:flutter/material.dart';
import 'package:foodfleet/models/restaurant_model.dart';
import 'package:foodfleet/screens/customers/screens/main_screens_controller.dart';

class RestaurantCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final String? distanceLabel;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    this.distanceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MainScreen(restaurant: restaurant),
          ),
        );
      },
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── IMAGE ──
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: _buildImage(restaurant.imageUrl),
            ),

            // ── DETAILS ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(status: restaurant.status),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            restaurant.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.restaurant_menu_outlined,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            restaurant.cuisineTypes.isNotEmpty
                                ? restaurant.cuisineTypes.join(', ')
                                : 'Various cuisines',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        // ── DISTANCE LABEL ──
                        if (distanceLabel != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F2A12).withOpacity(0.07),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.directions_walk,
                                    size: 10, color: Color(0xFF0F2A12)),
                                const SizedBox(width: 3),
                                Text(
                                  distanceLabel!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F2A12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── ARROW ──
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 110,
        height: 110,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.restaurant, size: 36, color: Colors.grey),
        ),
      );
    }
    return Image.network(
      imageUrl,
      width: 110,
      height: 110,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 110,
          height: 110,
          color: Colors.grey.shade100,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 110,
          height: 110,
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.restaurant, size: 36, color: Colors.grey),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Open' : 'Closed',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }
}
