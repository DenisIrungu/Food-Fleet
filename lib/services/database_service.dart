import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/user_model.dart';
import '/models/restaurant_model.dart';
import '/utils/constants.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================
  // USER MANAGEMENT (Single Storage)
  // ============================================

  // ✅ Save user data to Firestore (only in main 'users' collection)
  Future<void> addUser(UserModel user) async {
    try {
      await _firestore.collection(COLLECTION_USERS).doc(user.uid).set(user.toMap());
      print("✅ User saved successfully in 'users' collection.");
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

  // ✅ Delete user
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(COLLECTION_USERS).doc(uid).delete();
      print("✅ User deleted successfully.");
    } catch (e) {
      print("❌ Error deleting user: $e");
      rethrow;
    }
  }

  // ✅ Get user data by UID
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

  // ✅ Get all users by role
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

  // ✅ Check if super admin exists
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

  // ✅ Create Super Admin (once)
  Future<void> createSuperAdmin(String uid, String email, String username) async {
    try {
      UserModel superAdmin = UserModel(
        uid: uid,
        email: email,
        role: ROLE_SUPER_ADMIN,
        customerName: username,
        firstLogin: false,
        createdAt: DateTime.now(),
      );

      await addUser(superAdmin);
      print("✅ Super admin created successfully with UID: $uid");
    } catch (e) {
      print("❌ Error creating super admin: $e");
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
  // RESTAURANT MANAGEMENT
  // ============================================

  Future<String> createRestaurant(RestaurantModel restaurant) async {
    try {
      print('📝 Attempting to create restaurant: ${restaurant.name}');
      print('📋 Data: ${restaurant.toMap()}');

      // ✅ Use doc() instead of add() for controlled ID
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

  // ✅ Get all restaurants
  Stream<List<RestaurantModel>> getAllRestaurants() {
    return _firestore
        .collection(COLLECTION_RESTAURANTS)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RestaurantModel.fromFirestore(doc)).toList());
  }

  // ✅ Get restaurant by ID
  Future<RestaurantModel?> getRestaurantById(String restaurantId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(COLLECTION_RESTAURANTS).doc(restaurantId).get();
      if (doc.exists) return RestaurantModel.fromFirestore(doc);
      return null;
    } catch (e) {
      throw 'Failed to fetch restaurant: ${e.toString()}';
    }
  }

  // ✅ Get restaurant by admin UID
  Future<RestaurantModel?> getRestaurantByAdminUid(String adminUid) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(COLLECTION_RESTAURANTS)
          .where('adminUid', isEqualTo: adminUid)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) return RestaurantModel.fromFirestore(query.docs.first);
      return null;
    } catch (e) {
      throw 'Failed to fetch restaurant: ${e.toString()}';
    }
  }

  // ✅ Update restaurant data with timestamp
  Future<void> updateRestaurantData(
      String restaurantId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(COLLECTION_RESTAURANTS).doc(restaurantId).update(updates);
      print("✅ Restaurant data updated successfully.");
    } catch (e) {
      throw 'Failed to update restaurant: ${e.toString()}';
    }
  }

  // ✅ Delete restaurant
  Future<void> deleteRestaurant(String restaurantId) async {
    try {
      await _firestore.collection(COLLECTION_RESTAURANTS).doc(restaurantId).delete();
      print("✅ Restaurant deleted successfully.");
    } catch (e) {
      throw 'Failed to delete restaurant: ${e.toString()}';
    }
  }

  // ✅ Get restaurant count
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
}
