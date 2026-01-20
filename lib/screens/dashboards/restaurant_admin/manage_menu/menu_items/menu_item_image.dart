import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MenuItemImage extends StatelessWidget {
  /// Existing image URL (from Firestore)
  final String? imageUrl;

  /// Newly picked image (not yet uploaded)
  final XFile? pickedImage;

  /// Called when user taps to pick an image
  final ValueChanged<XFile?> onImageSelected;

  /// Optional remove callback
  final VoidCallback? onRemoveImage;

  const MenuItemImage({
    super.key,
    this.imageUrl,
    this.pickedImage,
    required this.onImageSelected,
    this.onRemoveImage,
  });

  /// Opens image picker
  Future<void> _pickImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        onImageSelected(image);
      }
    } catch (e) {
      debugPrint('Image picking failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Menu Item Image',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(context),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade200,
            child: ClipOval(
              child: _buildImage(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (pickedImage != null || (imageUrl?.isNotEmpty ?? false))
          TextButton.icon(
            onPressed: onRemoveImage,
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            label: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
      ],
    );
  }

  Widget _buildImage() {
    /// 1️⃣ Newly picked image (highest priority)
    if (pickedImage != null) {
      if (kIsWeb) {
        return Image.network(
          pickedImage!.path,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          },
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } else {
        return Image.file(
          File(pickedImage!.path),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
    }

    /// 2️⃣ Existing Firebase image
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    /// 3️⃣ No image
    return _placeholder();
  }

  Widget _placeholder() {
    return SizedBox(
      width: 100,
      height: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.image_outlined, size: 32, color: Colors.grey),
            SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
