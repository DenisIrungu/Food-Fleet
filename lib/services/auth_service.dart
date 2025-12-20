import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:foodfleet/models/user_model.dart';
import 'package:foodfleet/services/database_service.dart';
import '/utils/constants.dart';
import '/firebase_options.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();

  // ✅ Current authenticated user
  User? get currentUser => _auth.currentUser;

  // ✅ Auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // =====================================
  // SIGN IN
  // =====================================
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return userCredential.user == null
          ? null
          : await _databaseService.getUserData(userCredential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // =====================================
  // SIGN OUT
  // =====================================
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // =====================================
  // CUSTOMER REGISTRATION
  // =====================================
  Future<UserModel?> registerCustomer({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = UserModel(
        uid: credential.user!.uid,
        email: email.trim(),
        role: ROLE_CUSTOMER,
        fullName: name,
        firstLogin: false,
        createdAt: DateTime.now(),
      );

      await _databaseService.addUser(user);
      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // =====================================
  // CREATE RESTAURANT ADMIN (BY SUPER ADMIN)
  // =====================================
  Future<UserModel?> createRestaurantAdmin({
    required String email,
    required String password,
    required String restaurantId,
    required String restaurantName,
  }) async {
    try {
      final tempApp = await Firebase.initializeApp(
        name: 'TempRestaurantAdminApp',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 🔹 Set firstLogin = true for enforcement
      final adminUser = UserModel(
        uid: credential.user!.uid,
        email: email.trim(),
        role: ROLE_RESTAURANT_ADMIN,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        firstLogin: true, // ✅ enforce password change on first login
        createdAt: DateTime.now(),
      );

      await _databaseService.addUser(adminUser);

      await tempApp.delete();

      return adminUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to create restaurant admin: $e';
    }
  }

  // =====================================
  // PASSWORD CHANGE (OPTIONAL FEATURE)
  // =====================================
  Future<void> changePassword(String newPassword) async {
    final user = currentUser;
    if (user == null) return;

    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Please sign in again to change your password.';
      }
      throw _handleAuthException(e);
    }
  }

  // =====================================
  // ERROR HANDLING
  // =====================================
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak (min 6 characters).';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Authentication failed.';
    }
  }
}
