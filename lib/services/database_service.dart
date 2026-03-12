import 'dart:io'; // For File
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/user_model.dart';
import '/models/restaurant_model.dart';
import '/utils/constants.dart';
import 'storage_service.dart'; // Import StorageService

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================
  // USER MANAGEMENT
  // ============================================

  // ✅ Save user data (Global + Restaurant-linked riders)
  Future<void> addUser(UserModel user) async {
    try {
      await _firestore
          .collection(COLLECTION_USERS)
          .doc(user.uid)
          .set(user.toMap());
      print("✅ User saved in 'users' collection.");

      // If user is a rider, also store under their restaurant
      if (user.role == ROLE_RIDER && user.restaurantId != null) {
        await _firestore
            .collection(COLLECTION_RESTAURANTS)
            .doc(user.restaurantId)
            .collection('riders')
            .doc(user.uid)
            .set(user.toMap());
        print("✅ Rider also saved under restaurant '${user.restaurantName}'.");
      }
    } catch (e) {
      print("❌ Error saving user data: $e");
      rethrow;
    }
  }

  // ✅ Update user
  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(COLLECTION_USERS).doc(uid).update(updates);
      print("✅ User updated successfully.");
    } catch (e) {
      print("❌ Error updating user: $e");
      rethrow;
    }
  }

  // MOBILE
  Future<String?> updateProfilePicture(String uid, File imageFile) async {
    try {
      final storageService = StorageService();
      final url = await storageService.uploadProfilePicture(uid, imageFile);
      if (url == null) return null;

      await updateUser(uid, {
        'profilePictureUrl': url,
        'profilePictureUpdatedAt': FieldValue.serverTimestamp(),
      });

      print("✅ Profile picture uploaded and updated.");
      return url;
    } catch (e) {
      print("❌ Error uploading profile picture: $e");
      return null;
    }
  }

  // WEB
  Future<String?> updateProfilePictureWeb(
    String uid,
    Uint8List imageBytes,
  ) async {
    try {
      final storageService = StorageService();
      final url = await storageService.uploadProfilePictureWeb(uid, imageBytes);
      if (url == null) return null;

      await updateUser(uid, {
        'profilePictureUrl': url,
        'profilePictureUpdatedAt': FieldValue.serverTimestamp(),
      });

      print("✅ Web profile picture uploaded.");
      return url;
    } catch (e) {
      print("❌ Web upload failed: $e");
      return null;
    }
  }

  // ✅ Delete user (also from restaurant if rider)
  Future<void> deleteUser(String uid, {String? restaurantId}) async {
    try {
      await _firestore.collection(COLLECTION_USERS).doc(uid).delete();
      print("✅ User deleted from main collection.");

      if (restaurantId != null) {
        await _firestore
            .collection(COLLECTION_RESTAURANTS)
            .doc(restaurantId)
            .collection('riders')
            .doc(uid)
            .delete();
        print("✅ Rider deleted from restaurant subcollection.");
      }
    } catch (e) {
      print("❌ Error deleting user: $e");
      rethrow;
    }
  }

  // ✅ Get user by UID
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection(COLLECTION_USERS).doc(uid).get();
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    } catch (e) {
      throw 'Failed to fetch user data: $e';
    }
  }

  // ✅ Real-time user stream
  Stream<UserModel?> getUserDataStream(String uid) {
    return _firestore
        .collection(COLLECTION_USERS)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // ✅ Get users by role
  Stream<List<UserModel>> getUsersByRole(String role) {
    return _firestore
        .collection(COLLECTION_USERS)
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  // ✅ Role-based user streams
  Stream<List<UserModel>> getAllRestaurantAdmins() =>
      getUsersByRole(ROLE_RESTAURANT_ADMIN);
  Stream<List<UserModel>> getAllRiders() => getUsersByRole(ROLE_RIDER);
  Stream<List<UserModel>> getAllCustomers() => getUsersByRole(ROLE_CUSTOMER);

  // ✅ Check if Super Admin exists
  Future<bool> superAdminExists() async {
    try {
      QuerySnapshot query = await _firestore
          .collection(COLLECTION_USERS)
          .where('role', isEqualTo: ROLE_SUPER_ADMIN)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ✅ Create Super Admin
  Future<void> createSuperAdmin(
      String uid, String email, String username) async {
    try {
      UserModel superAdmin = UserModel(
        uid: uid,
        email: email,
        role: ROLE_SUPER_ADMIN,
        fullName: username,
        firstLogin: false,
        createdAt: DateTime.now(),
      );

      await addUser(superAdmin);
      print("✅ Super Admin created with UID: $uid");
    } catch (e) {
      print("❌ Error creating Super Admin: $e");
      rethrow;
    }
  }

  // ✅ Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(COLLECTION_USERS)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return UserModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // RIDER MANAGEMENT (Under Restaurants)
  // ============================================

  Stream<List<UserModel>> getRidersByRestaurant(String restaurantId) {
    return _firestore
        .collection(COLLECTION_RESTAURANTS)
        .doc(restaurantId)
        .collection('riders')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  Future<void> deleteRider(String restaurantId, String riderUid) async {
    try {
      await _firestore.collection(COLLECTION_USERS).doc(riderUid).delete();
      await _firestore
          .collection(COLLECTION_RESTAURANTS)
          .doc(restaurantId)
          .collection('riders')
          .doc(riderUid)
          .delete();
      print("✅ Rider deleted from both collections.");
    } catch (e) {
      print("❌ Error deleting rider: $e");
      rethrow;
    }
  }

  // ============================================
  // RESTAURANT MANAGEMENT
  // ============================================

  Future<String> createRestaurant(RestaurantModel restaurant) async {
    try {
      print('📝 Creating restaurant: ${restaurant.name}');

      // 🚫 PREVENT DUPLICATION (same email)
      final existing = await _firestore
          .collection(COLLECTION_RESTAURANTS)
          .where('email', isEqualTo: restaurant.email)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception(
          'Restaurant with email ${restaurant.email} already exists',
        );
      }

      // ✅ Safe to create
      final docRef = _firestore.collection(COLLECTION_RESTAURANTS).doc();

      await docRef.set({
        ...restaurant.toMap(),
        'id': docRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Restaurant created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stack) {
      print('❌ Firestore write failed: $e');
      print(stack);
      rethrow;
    }
  }

  // ✅ Super Admin creates restaurant & admin user
  Future<void> createRestaurantWithAdmin({
    required RestaurantModel restaurant,
    required UserModel adminUser,
  }) async {
    try {
      print("📝 Creating restaurant and admin...");

      // 🚫 Prevent duplicate restaurant by email
      final exists = await restaurantExistsByEmail(restaurant.email);
      if (exists) {
        throw Exception('Restaurant with this email already exists');
      }

      final restaurantId = await createRestaurant(restaurant);

      final updatedAdmin = adminUser.copyWith(
        restaurantId: restaurantId,
        role: ROLE_RESTAURANT_ADMIN,
      );

      await addUser(updatedAdmin);
      await updateRestaurantData(restaurantId, {'adminUid': adminUser.uid});

      // ✅ Auto-create default categories for the new restaurant
      await _createDefaultCategories(restaurantId);

      print("✅ Restaurant & admin successfully created and linked.");
    } catch (e) {
      print("❌ Error creating restaurant with admin: $e");
      rethrow;
    }
  }

  // ============================================
  // DEFAULT CATEGORIES
  // ============================================

  /// ✅ Creates "Chef's Special" and "Top of the Week" for a restaurant
  /// Skips creation if a category with the same name already exists
  Future<void> _createDefaultCategories(String restaurantId) async {
    try {
      final categoriesRef = _firestore
          .collection(COLLECTION_RESTAURANTS)
          .doc(restaurantId)
          .collection('categories');

      final defaultCategories = [
        {
          'name': "Chef's Special",
          'description': 'Featured dish recommended by the chef',
          'position': 0,
          'isActive': true,
          'isDefault': true,
          'restaurantId': restaurantId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Top of the Week',
          'description': 'Most popular dishes this week',
          'position': 1,
          'isActive': true,
          'isDefault': true,
          'restaurantId': restaurantId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      for (final category in defaultCategories) {
        // Check if category already exists to avoid duplicates
        final existing = await categoriesRef
            .where('name', isEqualTo: category['name'])
            .limit(1)
            .get();

        if (existing.docs.isEmpty) {
          await categoriesRef.add(category);
          print("✅ Default category '${category['name']}' created.");
        } else {
          print("⚠️ Category '${category['name']}' already exists, skipping.");
        }
      }
    } catch (e) {
      print("❌ Error creating default categories: $e");
      rethrow;
    }
  }

  /// ✅ One-time migration — adds default categories to all existing restaurants
  /// Safe to run multiple times — skips restaurants that already have them
  Future<void> migrateDefaultCategories() async {
    try {
      print("🔄 Starting default categories migration...");

      final restaurants =
          await _firestore.collection(COLLECTION_RESTAURANTS).get();

      int migrated = 0;
      int skipped = 0;

      for (final doc in restaurants.docs) {
        final restaurantId = doc.id;

        final categoriesRef = _firestore
            .collection(COLLECTION_RESTAURANTS)
            .doc(restaurantId)
            .collection('categories');

        // Check if Chef's Special exists
        final chefsSpecial = await categoriesRef
            .where('name', isEqualTo: "Chef's Special")
            .limit(1)
            .get();

        // Check if Top of the Week exists
        final topOfWeek = await categoriesRef
            .where('name', isEqualTo: 'Top of the Week')
            .limit(1)
            .get();

        final needsMigration =
            chefsSpecial.docs.isEmpty || topOfWeek.docs.isEmpty;

        if (needsMigration) {
          await _createDefaultCategories(restaurantId);
          migrated++;
          print("✅ Migrated restaurant: $restaurantId");
        } else {
          skipped++;
          print("⚠️ Skipped restaurant: $restaurantId (already has defaults)");
        }
      }

      print("✅ Migration complete. Migrated: $migrated, Skipped: $skipped");
    } catch (e) {
      print("❌ Migration failed: $e");
      rethrow;
    }
  }

  // ✅ Check if restaurant already exists by email
  Future<bool> restaurantExistsByEmail(String email) async {
    try {
      final query = await _firestore
          .collection(COLLECTION_RESTAURANTS)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print("❌ Error checking restaurant email: $e");
      rethrow;
    }
  }

  Stream<List<RestaurantModel>> getAllRestaurants() {
    return _firestore
        .collection(COLLECTION_RESTAURANTS)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RestaurantModel.fromFirestore(doc))
            .toList());
  }

  Future<RestaurantModel?> getRestaurantById(String restaurantId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(COLLECTION_RESTAURANTS)
          .doc(restaurantId)
          .get();
      if (doc.exists) return RestaurantModel.fromFirestore(doc);
      return null;
    } catch (e) {
      throw 'Failed to fetch restaurant: ${e.toString()}';
    }
  }

  Future<RestaurantModel?> getRestaurantByAdminUid(String adminUid) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(COLLECTION_RESTAURANTS)
          .where('adminUid', isEqualTo: adminUid)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return RestaurantModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch restaurant: ${e.toString()}';
    }
  }

  Future<void> updateRestaurantData(
      String restaurantId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection(COLLECTION_RESTAURANTS)
          .doc(restaurantId)
          .update(updates);
      print("✅ Restaurant updated successfully.");
    } catch (e) {
      throw 'Failed to update restaurant: ${e.toString()}';
    }
  }

  Future<void> deleteRestaurant(String restaurantId) async {
    try {
      await _firestore
          .collection(COLLECTION_RESTAURANTS)
          .doc(restaurantId)
          .delete();
      print("✅ Restaurant deleted successfully.");
    } catch (e) {
      throw 'Failed to delete restaurant: ${e.toString()}';
    }
  }

  Future<int> getRestaurantCount() async {
    try {
      AggregateQuerySnapshot snapshot =
          await _firestore.collection(COLLECTION_RESTAURANTS).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print("❌ Failed to count restaurants: $e");
      return 0;
    }
  }

  Stream<RestaurantModel?> streamRestaurantByAdminUid(String adminUid) {
    return _firestore
        .collection(COLLECTION_RESTAURANTS)
        .where('adminUid', isEqualTo: adminUid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return RestaurantModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    });
  }

  Stream<RestaurantModel?> streamRestaurantById(String restaurantId) {
    return _firestore
        .collection(COLLECTION_RESTAURANTS)
        .doc(restaurantId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return RestaurantModel.fromFirestore(doc);
      }
      return null;
    });
  }
}
