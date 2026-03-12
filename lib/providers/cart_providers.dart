import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foodfleet/models/cart_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:foodfleet/models/menu_item_model.dart';

class CartProvider extends ChangeNotifier {
  /// Map of restaurantId → list of cart items
  final Map<String, List<CartItem>> _carts = {};

  static const String _prefsPrefix = 'cart_';
  static const _uuid = Uuid();

  CartProvider() {
    _loadAllCarts();
  }

  // ─────────────────────────────────────────────
  // PUBLIC GETTERS
  // ─────────────────────────────────────────────

  /// Get cart items for a specific restaurant
  List<CartItem> cartFor(String restaurantId) => _carts[restaurantId] ?? [];

  /// Total item count across all restaurants (for badge)
  int get totalItemCount => _carts.values
      .fold(0, (sum, items) => sum + items.fold(0, (s, i) => s + i.quantity));

  /// Item count for a specific restaurant
  int itemCountFor(String restaurantId) =>
      cartFor(restaurantId).fold(0, (sum, item) => sum + item.quantity);

  /// Total price for a specific restaurant's cart
  double totalPriceFor(String restaurantId) =>
      cartFor(restaurantId).fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Whether a restaurant's cart is empty
  bool isEmptyFor(String restaurantId) => cartFor(restaurantId).isEmpty;

  /// All restaurant IDs that have active carts
  List<String> get activeRestaurantIds =>
      _carts.keys.where((id) => _carts[id]!.isNotEmpty).toList();

  // ─────────────────────────────────────────────
  // CART ACTIONS
  // ─────────────────────────────────────────────

  /// Add item to a restaurant's cart
  void addToCart({
    required String restaurantId,
    required MenuItemModel food,
    required List<MenuItemModel> selectedAddonItems,
    int quantity = 1,
  }) {
    _carts.putIfAbsent(restaurantId, () => []);

    // Check if same food + same addons already exists → increment quantity
    final existingIndex = _carts[restaurantId]!.indexWhere((item) =>
        item.food.id == food.id &&
        _sameAddons(item.selectedAddonItems, selectedAddonItems));

    if (existingIndex >= 0) {
      _carts[restaurantId]![existingIndex].quantity += quantity;
    } else {
      _carts[restaurantId]!.add(CartItem(
        id: _uuid.v4(),
        food: food,
        selectedAddonItems: selectedAddonItems,
        quantity: quantity,
      ));
    }

    _persistCart(restaurantId);
    notifyListeners();
  }

  /// Increment quantity of a cart item
  void incrementQuantity(String restaurantId, String cartItemId) {
    final item = _findItem(restaurantId, cartItemId);
    if (item != null) {
      item.quantity++;
      _persistCart(restaurantId);
      notifyListeners();
    }
  }

  /// Decrement quantity — removes item if quantity reaches 0
  void decrementQuantity(String restaurantId, String cartItemId) {
    final cart = _carts[restaurantId];
    if (cart == null) return;

    final item = _findItem(restaurantId, cartItemId);
    if (item != null) {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        cart.remove(item);
      }
      _persistCart(restaurantId);
      notifyListeners();
    }
  }

  /// Remove a specific item from a restaurant's cart
  void removeItem(String restaurantId, String cartItemId) {
    _carts[restaurantId]?.removeWhere((item) => item.id == cartItemId);
    _persistCart(restaurantId);
    notifyListeners();
  }

  /// Clear all items for a specific restaurant
  void clearCart(String restaurantId) {
    _carts[restaurantId] = [];
    _persistCart(restaurantId);
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // PERSISTENCE
  // ─────────────────────────────────────────────

  Future<void> _loadAllCarts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefsPrefix));

    for (final key in keys) {
      final restaurantId = key.replaceFirst(_prefsPrefix, '');
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        try {
          final List<dynamic> jsonList = jsonDecode(jsonString);
          _carts[restaurantId] =
              jsonList.map((e) => CartItem.fromJson(e)).toList();
        } catch (e) {
          debugPrint('Error loading cart for $restaurantId: $e');
        }
      }
    }

    notifyListeners();
  }

  Future<void> _persistCart(String restaurantId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = _carts[restaurantId] ?? [];
    final jsonString = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString('$_prefsPrefix$restaurantId', jsonString);
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  CartItem? _findItem(String restaurantId, String cartItemId) {
    try {
      return _carts[restaurantId]?.firstWhere((item) => item.id == cartItemId);
    } catch (_) {
      return null;
    }
  }

  bool _sameAddons(List<MenuItemModel> a, List<MenuItemModel> b) {
    if (a.length != b.length) return false;
    final aIds = a.map((e) => e.id).toSet();
    final bIds = b.map((e) => e.id).toSet();
    return aIds.containsAll(bIds);
  }
}
