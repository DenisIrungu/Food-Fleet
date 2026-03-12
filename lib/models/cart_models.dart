import 'dart:convert';
import 'package:foodfleet/models/menu_item_model.dart';

class CartItem {
  final String id; // unique per cart entry
  final MenuItemModel food;
  final List<MenuItemModel> selectedAddonItems;
  int quantity;

  CartItem({
    required this.id,
    required this.food,
    required this.selectedAddonItems,
    this.quantity = 1,
  });

  double get totalPrice {
    final addonTotal =
        selectedAddonItems.fold(0.0, (sum, addon) => sum + addon.price);
    return (food.price + addonTotal) * quantity;
  }

  // ── Serialization ──

  Map<String, dynamic> toJson() => {
        'id': id,
        'food': _menuItemToJson(food),
        'selectedAddonItems': selectedAddonItems.map(_menuItemToJson).toList(),
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      food: _menuItemFromJson(json['food'] as Map<String, dynamic>),
      selectedAddonItems: (json['selectedAddonItems'] as List<dynamic>)
          .map((e) => _menuItemFromJson(e as Map<String, dynamic>))
          .toList(),
      quantity: json['quantity'] as int,
    );
  }

  static Map<String, dynamic> _menuItemToJson(MenuItemModel item) => {
        'id': item.id,
        'restaurantId': item.restaurantId,
        'categoryId': item.categoryId,
        'name': item.name,
        'description': item.description,
        'imageUrl': item.imageUrl,
        'price': item.price,
        'isAvailable': item.isAvailable,
        'isAddon': item.isAddon,
        'addonGroupIds': item.addonGroupIds,
        'position': item.position,
        'createdAt': item.createdAt.toIso8601String(),
        'updatedAt': item.updatedAt.toIso8601String(),
      };

  static MenuItemModel _menuItemFromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] as String,
      restaurantId: json['restaurantId'] as String,
      categoryId: json['categoryId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      isAvailable: json['isAvailable'] as bool? ?? true,
      isAddon: json['isAddon'] as bool? ?? false,
      addonGroupIds: List<String>.from(json['addonGroupIds'] ?? []),
      position: json['position'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
