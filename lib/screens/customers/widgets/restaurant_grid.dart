import 'package:flutter/material.dart';
import 'package:foodfleet/models/restaurant_model.dart';
import 'restaurant_card.dart';

class RestaurantGrid extends StatelessWidget {
  final List<RestaurantModel> restaurants;

  const RestaurantGrid({
    super.key,
    required this.restaurants,
  });

  int _gridCount(double width) {
    if (width > 1300) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: width > 600 ? 40 : 16,
        vertical: 10,
      ),
      itemCount: restaurants.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridCount(width),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, index) {
        return RestaurantCard(
          restaurant: restaurants[index],
        );
      },
    );
  }
}
