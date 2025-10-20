import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/restaurant_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class RestaurantController extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  RestaurantController();

  // Stream restaurants
  Stream<List<RestaurantModel>> getRestaurantsStream() =>
      _databaseService.getAllRestaurants();

  // Pick image (optional)
  Future<XFile?> pickImage() async {
    try {
      return await _storage_service_pick();
    } catch (e) {
      print('❌ pickImage error: $e');
      return null;
    }
  }

  Future<XFile?> _storage_service_pick() async {
    return await _storageService.pickImageFromGallery();
  }

  /// -------------------------
  /// Simplified Create Restaurant
  /// - Only writes restaurant doc to Firestore (super admin must be signed in)
  /// - No Auth user creation, no image upload (we'll add those later after this works)
  /// - Robust logging and timeout to avoid silent freezes
  Future<bool> createRestaurant({
    required String name,
    required String email,
    required String password, // kept for future use, currently ignored
    required String phone,
    required String address,
    required List<String> cuisines,
    String? description,
    XFile? image, // kept for future integration, currently ignored
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🚀 [CreateRestaurant] Entered simplified flow');
      print('📧 email: $email | name: $name | phone: $phone');

      // Build data map (defensive: ensure types are what Firestore expects)
      final Map<String, dynamic> data = {
        'name': name,
        'adminUid': null, // no admin user yet; can be updated later
        'email': email,
        'phone': phone,
        'address': address,
        'cuisineTypes': cuisines,
        'description': description ?? '',
        'imageUrl': null,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('📝 [CreateRestaurant] Writing document to collection: $COLLECTION_RESTAURANTS');
      print('📦 Data preview (no timestamps): ${{
        'name': data['name'],
        'email': data['email'],
        'phone': data['phone'],
        'address': data['address'],
        'cuisineTypes': data['cuisineTypes'],
        'description': data['description'],
        'status': data['status'],
      }}');

      // Use a timeout to surface network/rules problems quickly
      final docRef = await _firestore
          .collection(COLLECTION_RESTAURANTS)
          .add(data)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception('⏱️ Firestore add() timed out — check network or rules.');
      });

      print('✅ [CreateRestaurant] Firestore doc created with ID: ${docRef.id}');

      // Optional: if you want to keep DatabaseService in sync, you can return that id
      // or call any further DB helpers here. For now we show success and return true.
      Fluttertoast.showToast(
        msg: '✅ Restaurant created successfully!',
        backgroundColor: Colors.green,
      );

      return true;
    } on FirebaseException catch (e, s) {
      // Firestore-specific errors (permissions, etc.)
      print('❌ [CreateRestaurant] FirebaseException: ${e.code} - ${e.message}');
      print(s);
      Fluttertoast.showToast(
        msg: '❌ Firestore error: ${e.message}',
        backgroundColor: Colors.red,
      );
      return false;
    } catch (e, s) {
      print('❌ [CreateRestaurant] Unexpected error: $e');
      print(s);
      Fluttertoast.showToast(
        msg: '❌ Error: ${e.toString()}',
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -------------------------
  // Delete Restaurant
  // -------------------------
  Future<bool> deleteRestaurant(RestaurantModel restaurant) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🗑️ Deleting restaurant ${restaurant.id}...');
      await _database_service_delete(restaurant.id);
await _databaseService.deleteUser(restaurant.adminUid);


      Fluttertoast.showToast(
        msg: '✅ Restaurant deleted successfully!',
        backgroundColor: Colors.green,
      );
      return true;
    } catch (e, s) {
      print('❌ [DeleteRestaurant] Error: $e');
      print(s);
      Fluttertoast.showToast(
        msg: '❌ Failed to delete: ${e.toString()}',
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // internal wrapper to call the existing database service delete with logs
  Future<void> _database_service_delete(String restaurantId) async {
    try {
      print('🔁 Calling DatabaseService.deleteRestaurant($restaurantId)');
      await _databaseService.deleteRestaurant(restaurantId).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('⏱️ deleteRestaurant() timed out');
        },
      );
      print('✅ DatabaseService.deleteRestaurant done');
    } catch (e) {
      print('❌ _database_service_delete error: $e');
      rethrow;
    }
  }
}
