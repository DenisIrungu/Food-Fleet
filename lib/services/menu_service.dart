import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category_model.dart';
import '../models/menu_item_model.dart';

class MenuService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final String restaurantId;

  MenuService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    required this.restaurantId,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // ===========================
  // FIRESTORE REFERENCES
  // ===========================

  CollectionReference<Map<String, dynamic>> get _categoriesRef => _firestore
      .collection('restaurants')
      .doc(restaurantId)
      .collection('categories');

  CollectionReference<Map<String, dynamic>> _menuItemsRef(String categoryId) =>
      _categoriesRef.doc(categoryId).collection('menu_items');

  // ===========================
  // CATEGORIES
  // ===========================

  Future<List<CategoryModel>> getCategories({bool onlyActive = true}) async {
    try {
      Query query = _categoriesRef.orderBy('position');
      if (onlyActive) {
        query = query.where('isActive', isEqualTo: true);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  Future<void> createCategory(CategoryModel category) async {
    await _categoriesRef.add(category.toMap());
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _categoriesRef.doc(category.id).update(category.toMap());
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoriesRef.doc(categoryId).delete();
  }

  Stream<List<CategoryModel>> streamCategories({bool onlyActive = true}) {
    Query query = _categoriesRef.orderBy('position');
    if (onlyActive) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => CategoryModel.fromFirestore(doc))
              .toList(),
        );
  }

  // ===========================
  // MENU ITEMS (UNDER CATEGORY)
  // ===========================

  Future<List<MenuItemModel>> getMenuItemsByCategory(
    String categoryId, {
    bool onlyAvailable = true,
  }) async {
    try {
      Query query = _menuItemsRef(categoryId).orderBy('position');

      if (onlyAvailable) {
        query = query.where('isAvailable', isEqualTo: true);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching menu items: $e');
      return [];
    }
  }

  Stream<List<MenuItemModel>> streamMenuItemsByCategory({
    required String categoryId,
    required bool isAdmin,
  }) {
    Query query = _menuItemsRef(categoryId).orderBy('position');

    if (!isAdmin) {
      query = query.where('isAvailable', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      debugPrint(
          'Fetched ${snapshot.docs.length} menu items for category $categoryId');
      return snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList();
    });
  }

  // ===========================
  // IMAGE UPLOAD (WEB + MOBILE)
  // ===========================

  Future<String> uploadMenuItemImage({
    required XFile image,
    required String categoryId,
    required String menuItemId,
  }) async {
    try {
      debugPrint('🔵 Upload started');
      debugPrint('   Restaurant ID: $restaurantId');
      debugPrint('   Category ID: $categoryId');
      debugPrint('   Menu Item ID: $menuItemId');

      final ref = _storage
          .ref()
          .child('restaurants')
          .child(restaurantId)
          .child('categories')
          .child(categoryId)
          .child('menu_items')
          .child('$menuItemId.jpg');

      debugPrint('🔵 Storage path: ${ref.fullPath}');

      UploadTask uploadTask;

      if (kIsWeb) {
        debugPrint('🔵 Web platform detected, reading bytes...');
        final Uint8List bytes = await image.readAsBytes();
        debugPrint('🔵 Bytes read: ${bytes.length}');
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        debugPrint('🔵 Mobile platform detected');
        uploadTask = ref.putFile(File(image.path));
      }

      debugPrint('🔵 Starting upload task...');
      final snapshot = await uploadTask;
      debugPrint('🟢 Upload complete, getting URL...');

      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('🟢 Download URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('🔴 Upload error: $e');
      debugPrint('🔴 Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<void> deleteMenuItemImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return;
      await _storage.refFromURL(imageUrl).delete();
    } catch (e) {
      debugPrint('Error deleting menu item image: $e');
    }
  }

  // ===========================
  // CRUD (CATEGORY SCOPED)
  // ===========================

  Future<DocumentReference<Map<String, dynamic>>> createMenuItem({
    required String categoryId,
    required MenuItemModel item,
  }) async {
    return await _menuItemsRef(categoryId).add(item.toMap());
  }

  Future<void> updateMenuItem({
    required String categoryId,
    required MenuItemModel item,
  }) async {
    await _menuItemsRef(categoryId).doc(item.id).update(item.toMap());
  }

  Future<void> deleteMenuItem({
    required String categoryId,
    required MenuItemModel item,
  }) async {
    try {
      if (item.imageUrl.isNotEmpty) {
        await deleteMenuItemImage(item.imageUrl);
      }
      await _menuItemsRef(categoryId).doc(item.id).delete();
    } catch (e) {
      debugPrint('Error deleting menu item: $e');
      rethrow;
    }
  }

  Future<void> setMenuItemAvailability({
    required String categoryId,
    required String itemId,
    required bool isAvailable,
  }) async {
    await _menuItemsRef(categoryId).doc(itemId).update({
      'isAvailable': isAvailable,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> updateMenuItemPositions({
    required String categoryId,
    required Map<String, int> positions,
  }) async {
    final batch = _firestore.batch();

    positions.forEach((id, pos) {
      batch.update(_menuItemsRef(categoryId).doc(id), {
        'position': pos,
        'updatedAt': Timestamp.now(),
      });
    });

    await batch.commit();
  }
}
