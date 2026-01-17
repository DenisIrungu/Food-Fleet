import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';

class MenuService {
  final FirebaseFirestore _firestore;
  final String restaurantId;

  MenuService({FirebaseFirestore? firestore, required this.restaurantId})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Firestore references
  CollectionReference<Map<String, dynamic>> get _categoriesRef => _firestore
      .collection('restaurants')
      .doc(restaurantId)
      .collection('categories');

  CollectionReference<Map<String, dynamic>> get _menuItemsRef => _firestore
      .collection('restaurants')
      .doc(restaurantId)
      .collection('menu_items');

  // ===========================
  // CATEGORIES
  // ===========================

  /// Get categories (default: only active)
  Future<List<CategoryModel>> getCategories({bool onlyActive = true}) async {
    try {
      Query query = _categoriesRef.orderBy('position');

      if (onlyActive) {
        query = query.where('isActive', isEqualTo: true);
      }

      final snapshot = await query.get();

      final categories = snapshot.docs
          .map((doc) {
            try {
              return CategoryModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Invalid category doc ${doc.id}: $e');
              return null;
            }
          })
          .whereType<CategoryModel>()
          .toList();

      debugPrint(
          'Fetched categories: ${categories.map((c) => c.name).toList()}');
      return categories;
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  /// Create category
  Future<void> createCategory(CategoryModel category) async {
    try {
      await _categoriesRef.add(category.toMap());
    } catch (e) {
      debugPrint('Error creating category: $e');
      rethrow;
    }
  }

  /// Update category
  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _categoriesRef.doc(category.id).update(category.toMap());
    } catch (e) {
      debugPrint('Error updating category ${category.id}: $e');
      rethrow;
    }
  }

  /// Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categoriesRef.doc(categoryId).delete();
    } catch (e) {
      debugPrint('Error deleting category $categoryId: $e');
      rethrow;
    }
  }

  /// Stream categories dynamically
  Stream<List<CategoryModel>> streamCategories({bool onlyActive = true}) {
    Query query = _categoriesRef.orderBy('position');
    if (onlyActive) query = query.where('isActive', isEqualTo: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return CategoryModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Invalid category doc ${doc.id}: $e');
              return null;
            }
          })
          .whereType<CategoryModel>()
          .toList();
    });
  }

  // ===========================
  // MENU ITEMS
  // ===========================

  /// Get menu items per category
  Future<List<MenuItemModel>> getMenuItemsByCategory(String categoryId,
      {bool onlyAvailable = true}) async {
    try {
      Query query = _menuItemsRef
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('position');

      if (onlyAvailable) {
        query = query.where('isAvailable', isEqualTo: true);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching menu items for category $categoryId: $e');
      return [];
    }
  }

  /// Get all menu items
  Future<List<MenuItemModel>> getAllMenuItems() async {
    try {
      final snapshot = await _menuItemsRef.orderBy('position').get();
      return snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching all menu items: $e');
      return [];
    }
  }

  /// Stream menu items by category
  Stream<List<MenuItemModel>> streamMenuItemsByCategory(
      {required String categoryId, required bool isAdmin}) {
    Query query = _menuItemsRef.orderBy('position');
    if (categoryId.isNotEmpty)
      query = query.where('categoryId', isEqualTo: categoryId);
    if (!isAdmin) query = query.where('isAvailable', isEqualTo: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return MenuItemModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Invalid menu item doc ${doc.id}: $e');
              return null;
            }
          })
          .whereType<MenuItemModel>()
          .toList();
    });
  }

  /// Create menu item
  Future<void> createMenuItem(MenuItemModel item) async {
    try {
      await _menuItemsRef.add(item.toMap());
    } catch (e) {
      debugPrint('Error creating menu item: $e');
      rethrow;
    }
  }

  /// Update menu item
  Future<void> updateMenuItem(MenuItemModel item) async {
    try {
      await _menuItemsRef.doc(item.id).update(item.toMap());
    } catch (e) {
      debugPrint('Error updating menu item ${item.id}: $e');
      rethrow;
    }
  }

  /// Delete menu item
  Future<void> deleteMenuItem(String itemId) async {
    try {
      await _menuItemsRef.doc(itemId).delete();
    } catch (e) {
      debugPrint('Error deleting menu item $itemId: $e');
      rethrow;
    }
  }

  /// Toggle availability
  Future<void> setMenuItemAvailability(String itemId, bool isAvailable) async {
    try {
      await _menuItemsRef.doc(itemId).update({
        'isAvailable': isAvailable,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error setting availability for $itemId: $e');
      rethrow;
    }
  }

  /// Update menu item positions
  Future<void> updateMenuItemPositions(Map<String, int> positions) async {
    try {
      final batch = _firestore.batch();
      positions.forEach((id, pos) {
        batch.update(_menuItemsRef.doc(id),
            {'position': pos, 'updatedAt': Timestamp.now()});
      });
      await batch.commit();
    } catch (e) {
      debugPrint('Error updating menu item positions: $e');
      rethrow;
    }
  }
}
