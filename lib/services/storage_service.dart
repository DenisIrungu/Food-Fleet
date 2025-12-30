import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /* ------------------------------------------
   PICK IMAGE
  -------------------------------------------*/

  Future<XFile?> pickImageFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('❌ Image pick error: $e');
      return null;
    }
  }

  /* ------------------------------------------
   UPLOAD (MOBILE / DESKTOP)
  -------------------------------------------*/

  Future<String?> uploadProfilePicture(
    String uid,
    File imageFile,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final ref = _storage.ref(
        'profile_pictures/$uid/$timestamp.jpg',
      );

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public,max-age=3600',
      );

      await ref.putFile(imageFile, metadata);

      final url = await ref.getDownloadURL();
      debugPrint('✅ Profile image uploaded: $url');

      return url;
    } catch (e) {
      debugPrint('❌ Upload failed: $e');
      return null;
    }
  }

  /* ------------------------------------------
   UPLOAD (WEB) — FIXED & ANDROID SAFE
  -------------------------------------------*/

  Future<String?> uploadProfilePictureWeb(
    String uid,
    Uint8List imageBytes,
  ) async {
    try {
      // ✅ Decode browser image
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        debugPrint('❌ Failed to decode web image');
        return null;
      }

      // ✅ Re-encode as REAL JPEG
      final jpegBytes = Uint8List.fromList(
        img.encodeJpg(decoded, quality: 85),
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final ref = _storage.ref(
        'profile_pictures/$uid/$timestamp.jpg',
      );

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public,max-age=3600',
      );

      await ref.putData(jpegBytes, metadata);

      final url = await ref.getDownloadURL();
      debugPrint('✅ Web image uploaded (re-encoded): $url');

      return url;
    } catch (e) {
      debugPrint('❌ Web upload failed: $e');
      return null;
    }
  }

  /* ------------------------------------------
   OPTIONAL CLEANUP (MANUAL ONLY)
   ⚠️ DO NOT call during upload
  -------------------------------------------*/

  Future<void> cleanupOldProfilePictures(String uid) async {
    try {
      final folderRef = _storage.ref('profile_pictures/$uid');
      final result = await folderRef.listAll();

      if (result.items.length <= 1) return;

      result.items.sort((a, b) => b.name.compareTo(a.name));

      for (int i = 1; i < result.items.length; i++) {
        await result.items[i].delete();
        debugPrint('🗑️ Deleted old image: ${result.items[i].name}');
      }
    } catch (e) {
      debugPrint('⚠️ Cleanup failed: $e');
    }
  }
}
