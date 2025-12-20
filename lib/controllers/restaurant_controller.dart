import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/restaurant_model.dart';
import '../models/user_model.dart';
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

  // ✅ Stream all restaurants
  Stream<List<RestaurantModel>> getRestaurantsStream() =>
      _databaseService.getAllRestaurants();

  // ✅ Pick image (optional)
  Future<XFile?> pickImage() async {
    try {
      return await _storageService.pickImageFromGallery();
    } catch (e) {
      print('❌ pickImage error: $e');
      return null;
    }
  }

    /// ✅ Create Restaurant + Admin
  Future<bool> createRestaurant({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required List<String> cuisines,
    String? description,
    XFile? image,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🚀 [CreateRestaurant] Start creating restaurant + admin');

      // Step 1️⃣: Create restaurant object (adminUid temporarily empty)
      final restaurant = RestaurantModel(
        id: '',
        name: name,
        adminUid: '', // initially empty, will update after admin creation
        email: email,
        phone: phone,
        address: address,
        cuisineTypes: cuisines,
        description: description ?? '',
        imageUrl: null,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Step 2️⃣: Save restaurant to Firestore → get ID
      final restaurantId = await _databaseService.createRestaurant(restaurant);
      print('✅ Restaurant created with ID: $restaurantId');

      // Step 3️⃣: Create Restaurant Admin user
      final newAdmin = await _authService.createRestaurantAdmin(
        email: email,
        password: password,
        restaurantId: restaurantId,
        restaurantName: name,
      );

      if (newAdmin != null) {
        // Step 4️⃣: Update restaurant with admin UID
        await _databaseService.updateRestaurantData(restaurantId, {
          'adminUid': newAdmin.uid,
        });
        print('✅ Linked admin ${newAdmin.uid} to restaurant $restaurantId');

        Fluttertoast.showToast(
          msg: '✅ Restaurant & Admin created successfully!',
          backgroundColor: Colors.green,
        );
        return true;
      } else {
        print('❌ Failed to create admin user.');
        Fluttertoast.showToast(
          msg: '❌ Failed to create restaurant admin.',
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e, s) {
      print('❌ [CreateRestaurant] Error: $e');
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


  /// ✅ Delete restaurant + admin user
  Future<bool> deleteRestaurant(RestaurantModel restaurant) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🗑️ Deleting restaurant ${restaurant.id}...');

      // Step 1️⃣: Delete restaurant doc
      await _databaseService.deleteRestaurant(restaurant.id);

      // Step 2️⃣: Delete admin user (if exists)
      await _databaseService.deleteUser(restaurant.adminUid!);
      print('✅ Deleted linked admin user');
    
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
}
