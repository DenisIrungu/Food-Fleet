import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';
import '../models/addon_group_model.dart';

class PreviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ----------------------------------------------------------
  // Fetch Categories
  // ----------------------------------------------------------
  Future<List<CategoryModel>> fetchCategories(String restaurantId) async {
    final snapshot = await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('categories')
        .orderBy('position')
        .get();

    return snapshot.docs
        .map((doc) => CategoryModel.fromFirestore(doc))
        .toList();
  }

  // ----------------------------------------------------------
  // Fetch Menu Items Per Category
  // ----------------------------------------------------------
  Future<List<MenuItemModel>> fetchMenuItemsByCategory(
      String restaurantId, String categoryId) async {
    final snapshot = await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('categories')
        .doc(categoryId)
        .collection('menu_items')
        .where('isAddon', isEqualTo: false)
        .orderBy('position')
        .get();

    return snapshot.docs
        .map((doc) => MenuItemModel.fromFirestore(doc))
        .toList();
  }

  // ----------------------------------------------------------
  // Fetch Addon Groups by IDs (Chunked for Firestore limit)
  // ----------------------------------------------------------
  Future<List<AddonGroupModel>> fetchAddonGroupsByIds(
      String restaurantId, List<String> ids) async {
    if (ids.isEmpty) return [];

    final List<AddonGroupModel> results = [];

    for (int i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);

      final snapshot = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('addon_groups')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      results.addAll(
          snapshot.docs.map((doc) => AddonGroupModel.fromFirestore(doc)));
    }

    return results;
  }

  // ----------------------------------------------------------
  // Fetch Addon Menu Items by IDs (Chunked)
  // ----------------------------------------------------------
  Future<List<MenuItemModel>> fetchAddonItemsByIds(
      String restaurantId, List<String> ids) async {
    if (ids.isEmpty) return [];

    final List<MenuItemModel> results = [];

    for (int i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);

      final snapshot = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu_items')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      results
          .addAll(snapshot.docs.map((doc) => MenuItemModel.fromFirestore(doc)));
    }

    return results;
  }
}
