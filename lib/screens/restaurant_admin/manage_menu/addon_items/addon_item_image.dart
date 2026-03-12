import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Handles image picking and uploading for addon items
class AddonItemImageHandler {
  final ImagePicker _imagePicker = ImagePicker();
  final String restaurantId;

  AddonItemImageHandler({required this.restaurantId});

  /// Pick image from gallery
  Future<XFile?> pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      return pickedFile;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload image to Firebase Storage (works for both web and mobile)
  Future<String?> uploadImage(XFile imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('restaurants')
          .child(restaurantId)
          .child('addon_items')
          .child(fileName);

      // Upload differently for web vs mobile
      final uploadTask = kIsWeb
          ? await storageRef.putData(await imageFile.readAsBytes())
          : await storageRef.putFile(File(imageFile.path));

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }
}

/* --------------------------------------------------------
   Image Picker Widget
-------------------------------------------------------- */

class AddonItemImagePicker extends StatelessWidget {
  final XFile? selectedImage;
  final String? existingImageUrl;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  const AddonItemImagePicker({
    super.key,
    required this.selectedImage,
    required this.existingImageUrl,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasImage = selectedImage != null || existingImageUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.onSecondary,
          ),
        ),
        const SizedBox(height: 8),
        if (hasImage)
          _ImagePreview(
            selectedImage: selectedImage,
            existingImageUrl: existingImageUrl,
            onEdit: onPickImage,
            onRemove: onRemoveImage,
          )
        else
          _ImagePlaceholder(onTap: onPickImage),
      ],
    );
  }
}

/* --------------------------------------------------------
   Image Preview (when image exists)
-------------------------------------------------------- */

class _ImagePreview extends StatelessWidget {
  final XFile? selectedImage;
  final String? existingImageUrl;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _ImagePreview({
    required this.selectedImage,
    required this.existingImageUrl,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.onSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: selectedImage != null
                ? kIsWeb
                    ? Image.network(
                        selectedImage!.path,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ErrorIcon(colors),
                      )
                    : Image.file(
                        File(selectedImage!.path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ErrorIcon(colors),
                      )
                : Image.network(
                    existingImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ErrorIcon(colors),
                  ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              IconButton(
                onPressed: onEdit,
                style: IconButton.styleFrom(
                  backgroundColor: colors.tertiary,
                ),
                icon: Icon(Icons.edit, color: colors.onSurface),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onRemove,
                style: IconButton.styleFrom(
                  backgroundColor: colors.tertiary,
                ),
                icon: const Icon(Icons.delete, color: Colors.redAccent),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorIcon extends StatelessWidget {
  final ColorScheme colors;
  const _ErrorIcon(this.colors);

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.broken_image,
      size: 64,
      color: colors.onSecondary,
    );
  }
}

/* --------------------------------------------------------
   Image Placeholder (when no image)
-------------------------------------------------------- */

class _ImagePlaceholder extends StatelessWidget {
  final VoidCallback onTap;

  const _ImagePlaceholder({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.onSecondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.onSecondary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 48,
              color: colors.onSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to select image',
              style: TextStyle(
                color: colors.onSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
