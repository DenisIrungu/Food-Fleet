import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodfleet/utils/constants.dart';
import 'database_service.dart';

class SuperAdminInitService {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize super admin on first app launch
  Future<void> initializeSuperAdmin() async {
    try {
      print("👤 Initializing Super Admin...");

      // 1. Check if super admin already exists in Firestore
      bool exists = await _databaseService.superAdminExists();
      if (exists) {
        print("✅ Super admin already exists in Firestore.");
        return;
      }

      print("❌ Super admin not found in Firestore. Creating...");

      try {
        // 2. Try creating super admin in Firebase Auth
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: SUPER_ADMIN_EMAIL,
          password: SUPER_ADMIN_PASSWORD,
        );

        // 3. Create Firestore document for super admin
        await _databaseService.createSuperAdmin(
          userCredential.user!.uid,
          SUPER_ADMIN_EMAIL,
          SUPER_ADMIN_USERNAME,
        );

        print("✅ Super admin created in Auth + Firestore.");
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          print(
              "ℹ️ Super admin already exists in Firebase Auth. Syncing Firestore...");

          // Sign in temporarily to get UID
          UserCredential userCredential =
              await _auth.signInWithEmailAndPassword(
            email: SUPER_ADMIN_EMAIL,
            password: SUPER_ADMIN_PASSWORD,
          );

          // Create Firestore doc if missing
          await _databaseService.createSuperAdmin(
            userCredential.user!.uid,
            SUPER_ADMIN_EMAIL,
            SUPER_ADMIN_USERNAME,
          );

          print("✅ Firestore doc created for existing super admin.");

          // Sign out immediately so manual login is still required
          await _auth.signOut();
        } else {
          print("❌ Error creating super admin: ${e.message}");
        }
      }
    } catch (e) {
      print("❌ Unexpected error during super admin initialization: $e");
    }
  }
}
