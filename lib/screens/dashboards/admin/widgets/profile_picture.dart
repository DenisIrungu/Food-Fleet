import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodfleet/models/user_model.dart';
import 'package:foodfleet/models/restaurant_model.dart';
import 'package:foodfleet/services/database_service.dart';
import 'package:foodfleet/services/storage_service.dart';

class ProfilePictureWidget extends StatelessWidget {
  final UserModel userData;
  final RestaurantModel restaurant;
  final ColorScheme colors;

  const ProfilePictureWidget({
    super.key,
    required this.userData,
    required this.restaurant,
    required this.colors,
  });

  Future<void> _upload(BuildContext context) async {
    final db = DatabaseService();
    final storage = StorageService();

    try {
      final picked = await storage.pickImageFromGallery();
      if (picked == null) return;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await db.updateProfilePictureWeb(userData.uid, bytes);
      } else {
        await db.updateProfilePicture(
          userData.uid,
          File(picked.path),
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = userData.profilePictureUrl;

    // WEB — never load network image
    if (kIsWeb) {
      return GestureDetector(
        onTap: () => _upload(context),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: colors.primary,
          child: Text(
            restaurant.name.isNotEmpty ? restaurant.name[0].toUpperCase() : 'R',
            style: TextStyle(
              color: colors.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // MOBILE
    return GestureDetector(
      onTap: () => _upload(context),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: colors.primary,
        foregroundImage: (imageUrl != null && imageUrl.isNotEmpty)
            ? NetworkImage(imageUrl)
            : null,
        child: Text(
          restaurant.name.isNotEmpty ? restaurant.name[0].toUpperCase() : 'R',
          style: TextStyle(
            color: colors.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
