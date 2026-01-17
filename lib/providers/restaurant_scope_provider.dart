import 'package:flutter/material.dart';

class RestaurantScope extends ChangeNotifier {
  String _restaurantId = '';

  String get restaurantId => _restaurantId;

  void setRestaurant(String id) {
    if (_restaurantId == id) return;
    _restaurantId = id;
    notifyListeners();
  }

  bool get hasRestaurant => _restaurantId.isNotEmpty;
}
