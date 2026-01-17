import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  final String restaurantId;

  CategoryService({required this.restaurantId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get _hasRestaurant => restaurantId.isNotEmpty;

  // 🔹 Updated: Use restaurant subcollection
  CollectionReference<Map<String, dynamic>> get _categoryRef => _firestore
      .collection('restaurants')
      .doc(restaurantId)
      .collection('categories');

  // ======================================================
  // WATCH CATEGORIES
  // ======================================================
  Stream<List<CategoryModel>> watchCategories() {
    if (!_hasRestaurant) return const Stream.empty();

    return _categoryRef.orderBy('position').snapshots().map(
          (snapshot) => snapshot.docs.map(CategoryModel.fromFirestore).toList(),
        );
  }

  // ======================================================
  // CREATE CATEGORY
  // ======================================================
  Future<void> createCategory(CategoryModel category) async {
    if (!_hasRestaurant) throw Exception('Restaurant not set');
    await _categoryRef.add(category.toMap());
  }

  // ======================================================
  // UPDATE CATEGORY
  // ======================================================
  Future<void> updateCategory(CategoryModel category) async {
    if (!_hasRestaurant) throw Exception('Restaurant not set');
    await _categoryRef.doc(category.id).update(category.toMap());
  }

  // ======================================================
  // DELETE CATEGORY
  // ======================================================
  Future<void> deleteCategory(String categoryId) async {
    if (!_hasRestaurant) throw Exception('Restaurant not set');
    await _categoryRef.doc(categoryId).delete();
  }

  // ======================================================
  // UPDATE POSITIONS (REORDER)
  // ======================================================
  Future<void> updateCategoryPositions(List<CategoryModel> categories) async {
    if (!_hasRestaurant) return;

    final batch = _firestore.batch();

    for (int i = 0; i < categories.length; i++) {
      batch.update(
        _categoryRef.doc(categories[i].id),
        {'position': i},
      );
    }

    await batch.commit();
  }
}
