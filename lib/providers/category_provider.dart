import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodfleet/models/category_model.dart';
import 'package:foodfleet/providers/restaurant_scope_provider.dart';
import 'package:provider/provider.dart';

class CategoriesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;

  /// Load categories for current restaurant
  Future<void> fetchCategories(BuildContext context) async {
    final restaurantId = context.read<RestaurantScope>().restaurantId;
    if (restaurantId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    final snapshot = await _firestore
        .collection('categories')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('position')
        .get();

    _categories =
        snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();

    _isLoading = false;
    notifyListeners();
  }

  /// Create category (NO restaurantId passed from UI)
  Future<void> createCategory(
    BuildContext context, {
    required String name,
    String? description,
    bool isActive = true,
  }) async {
    final restaurantId = context.read<RestaurantScope>().restaurantId;
    if (restaurantId.isEmpty) return;

    final position = _categories.length;

    final category = CategoryModel(
      id: '',
      restaurantId: restaurantId,
      name: name,
      description: description,
      position: position,
      isActive: isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final doc = await _firestore.collection('categories').add(category.toMap());

    _categories.add(
      category.copyWith(),
    );

    notifyListeners();
  }

  /// Update category
  Future<void> updateCategory(CategoryModel category) async {
    await _firestore
        .collection('categories')
        .doc(category.id)
        .update(category.toMap());

    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      notifyListeners();
    }
  }

  /// Delete category
  Future<void> deleteCategory(String id) async {
    await _firestore.collection('categories').doc(id).delete();
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
