import 'package:flutter/material.dart';
import 'package:foodfleet/models/menu_item_model.dart';
import 'package:foodfleet/screens/customers/screens/menu/foodpage.dart';

// ================= TOP OF THE WEEK SECTION =================
/// Isolated widget — parent setState won't trigger its rebuild
class TopOfWeekSection extends StatelessWidget {
  final Stream<List<MenuItemModel>> stream;
  final String restaurantId;

  const TopOfWeekSection({
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
        if (items == null || items.isEmpty) return const TopOfWeekSkeleton();
        return SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) => TopFoodCard(
              item: items[index],
              restaurantId: restaurantId,
            ),
          ),
        );
      },
    );
  }
}

// ================= TOP FOOD CARD =================
class TopFoodCard extends StatelessWidget {
  final MenuItemModel item;
  final String restaurantId;

  const TopFoodCard({
    super.key,
    required this.item,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FoodPage(
            food: item,
            restaurantId: restaurantId,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            SizedBox(
              width: 140,
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              "Ksh ${item.price.toStringAsFixed(2)}",
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

// ================= TOP OF THE WEEK SKELETON =================
class TopOfWeekSkeleton extends StatelessWidget {
  const TopOfWeekSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 140,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 100,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 60,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
