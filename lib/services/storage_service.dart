import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('❌ Error picking image: $e');
      return null;
    }
  }

  // Upload restaurant logo or any image
  Future<String?> uploadImage(
    XFile imageFile, {
    required String folderName,
    required String fileId,
  }) async {
    try {
      final fileExtension = imageFile.path.split('.').last;
      final fileName = '${fileId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final Reference ref = _storage.ref().child('$folderName/$fileName');

      UploadTask uploadTask;

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        uploadTask = ref.putData(bytes);
      } else {
        uploadTask = ref.putFile(File(imageFile.path));
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  // Specific helper for restaurant logos
  Future<String?> uploadRestaurantLogo(XFile imageFile, String restaurantId) async {
    return await uploadImage(
      imageFile,
      folderName: 'restaurant_logos',
      fileId: restaurantId,
    );
  }
}
