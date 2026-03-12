import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:foodfleet/models/menu_item_model.dart';
import 'package:foodfleet/components/my_textfield.dart';
import 'package:foodfleet/components/mybutton.dart';
import 'addon_item_image.dart';

class AddonItemForm extends StatefulWidget {
  final String restaurantId;
  final MenuItemModel? existingItem;
  final VoidCallback onSaved;

  const AddonItemForm({
    super.key,
    required this.restaurantId,
    this.existingItem,
    required this.onSaved,
  });

  @override
  State<AddonItemForm> createState() => _AddonItemFormState();
}

class _AddonItemFormState extends State<AddonItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  late final AddonItemImageHandler _imageHandler;
  XFile? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _imageHandler = AddonItemImageHandler(restaurantId: widget.restaurantId);

    if (widget.existingItem != null) {
      _nameController.text = widget.existingItem!.name;
      _descriptionController.text = widget.existingItem!.description ?? '';
      _priceController.text = widget.existingItem!.price.toString();
      _existingImageUrl = widget.existingItem!.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? width * 0.3 : 16,
        vertical: 24,
      ),
      backgroundColor: colors.tertiary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(isEditing: widget.existingItem != null),
                const SizedBox(height: 24),

                /// Name
                MyTextField(
                  controller: _nameController,
                  hintText: 'Addon item name',
                  labelText: 'Name',
                  obscureText: false,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                /// Description
                MyTextField(
                  controller: _descriptionController,
                  hintText: 'Description (optional)',
                  labelText: 'Description',
                  obscureText: false,
                ),

                const SizedBox(height: 12),

                /// Price
                MyTextField(
                  controller: _priceController,
                  hintText: '0.00',
                  labelText: 'Price',
                  obscureText: false,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Price is required';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price < 0) {
                      return 'Enter a valid price';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                /// Image Picker
                AddonItemImagePicker(
                  selectedImage: _selectedImage,
                  existingImageUrl: _existingImageUrl,
                  onPickImage: _pickImage,
                  onRemoveImage: _removeImage,
                ),

                const SizedBox(height: 24),

                /// Info Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.onSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colors.onSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This addon item can be added to addon groups later',
                          style: TextStyle(
                            color: colors.onSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// Actions
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: MyButton(
                          text: 'Cancel',
                          color: colors.onSecondary.withOpacity(0.15),
                          foregroundColor: colors.onSecondary,
                          onPress: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MyButton(
                          text: widget.existingItem != null
                              ? 'Update Item'
                              : 'Create Item',
                          color: colors.onPrimary,
                          foregroundColor: colors.tertiary,
                          onPress: _saveAddonItem,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imageHandler.pickImage();
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _existingImageUrl = null;
    });
  }

  Future<void> _saveAddonItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final now = DateTime.now();

      // Upload image if new one selected
      String? imageUrl = _existingImageUrl;
      if (_selectedImage != null) {
        imageUrl = await _imageHandler.uploadImage(_selectedImage!);
        if (imageUrl == null) {
          // Upload failed
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image')),
            );
          }
          return;
        }
      }

      final firestore = FirebaseFirestore.instance;
      final menuItemsRef = firestore
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('menu_items');

      if (widget.existingItem != null) {
        // Update existing
        await menuItemsRef.doc(widget.existingItem!.id).update({
          'name': name,
          'description': description.isEmpty ? null : description,
          'price': price,
          'imageUrl': imageUrl,
          'updatedAt': Timestamp.fromDate(now),
        });
      } else {
        // Create new - get highest position first
        final snapshot =
            await menuItemsRef.where('isAddon', isEqualTo: true).get();

        int nextPosition = 0;
        if (snapshot.docs.isNotEmpty) {
          // Find max position in memory
          final positions = snapshot.docs
              .map((doc) => doc.data()['position'] as int? ?? 0)
              .toList();
          nextPosition = positions.reduce((a, b) => a > b ? a : b) + 1;
        }

        await menuItemsRef.add({
          'restaurantId': widget.restaurantId,
          'categoryId': '', // Addon items don't belong to categories
          'name': name,
          'description': description.isEmpty ? null : description,
          'price': price,
          'imageUrl': imageUrl,
          'isAvailable': true,
          'isAddon': true, // KEY: This marks it as an addon item
          'addonGroupIds': [], // Addon items don't have addon groups
          'position': nextPosition,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingItem != null
                  ? 'Addon item updated'
                  : 'Addon item created',
            ),
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

/* --------------------------------------------------------
   Header
-------------------------------------------------------- */

class _Header extends StatelessWidget {
  final bool isEditing;

  const _Header({required this.isEditing});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(Icons.add_shopping_cart, color: colors.primary, size: 28),
        const SizedBox(width: 12),
        Text(
          isEditing ? 'Edit Addon Item' : 'Create Addon Item',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }
}
