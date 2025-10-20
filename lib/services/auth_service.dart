import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:foodfleet/models/user_model.dart';
import 'package:foodfleet/services/database_service.dart';
import '/utils/constants.dart';
import '/firebase_options.dart'; // Make sure this file exists (from flutterfire configure)

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();

  // ✅ Get the current authenticated user
  User? get currentUser => _auth.currentUser;

  // ✅ Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ✅ Sign in with email and password
  Future<UserModel?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        return await _databaseService.getUserData(userCredential.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An error occurred. Please try again.';
    }
  }

  // ✅ Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Failed to sign out. Please try again.';
    }
  }

  // ✅ Register Customer (Self Registration)
  Future<UserModel?> registerCustomer({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        UserModel newUser = UserModel(
          uid: userCredential.user!.uid,
          email: email.trim(),
          role: ROLE_CUSTOMER,
          customerName: name,
          firstLogin: false,
          createdAt: DateTime.now(),
        );

        await _databaseService.addUser(newUser);
        return newUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to create account. Please try again.';
    }
  }

  // ✅ Create Restaurant Admin (without logging out Super Admin)
  Future<UserModel?> createRestaurantAdmin({
    required String email,
    required String password,
    required String restaurantId,
    required String restaurantName,
  }) async {
    try {
      // Initialize a temporary Firebase app
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TempRestaurantApp',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      // Create restaurant admin account on temporary app
      UserCredential userCredential = await tempAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Build new restaurant admin user model
      UserModel newUser = UserModel(
        uid: userCredential.user!.uid,
        email: email.trim(),
        role: ROLE_RESTAURANT_ADMIN,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        firstLogin: true,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _databaseService.addUser(newUser);

      // Delete temporary Firebase app
      await tempApp.delete();

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to create restaurant admin account: ${e.toString()}';
    }
  }

  // ✅ Change Password
  Future<void> changePassword(String newPassword) async {
    try {
      User? user = currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        await _databaseService
            .getUserData(user.uid)
            .then((u) => _databaseService.addUser(u!.copyWith(firstLogin: false)));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Please sign in again to change your password.';
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to change password. Please try again.';
    }
  }

  // ✅ Firebase Auth Exception handler
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
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
