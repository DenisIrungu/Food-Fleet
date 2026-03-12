import 'package:flutter/material.dart';
import 'package:foodfleet/models/addon_group_model.dart';
import 'package:foodfleet/models/category_model.dart';
import 'package:foodfleet/models/menu_item_model.dart';
import 'package:foodfleet/providers/restaurant_scope_provider.dart';
import 'package:foodfleet/screens/restaurant_admin/manage_menu/menu_items/menu_item_image.dart';
import 'package:foodfleet/services/addon_service.dart';
import 'package:foodfleet/services/menu_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class MenuItemForm extends StatefulWidget {
  final MenuItemModel? existingItem;
  final CategoryModel? initialCategory;

  const MenuItemForm({super.key, this.existingItem, this.initialCategory});

  @override
  State<MenuItemForm> createState() => _MenuItemFormState();
}

class _MenuItemFormState extends State<MenuItemForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;

  XFile? _pickedImage;

  bool _isAvailable = true;
  bool _isAddon = false;
  List<String> _addonGroupIds = [];

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _loadingCategories = true;
  bool _isSubmitting = false;

  // Addon groups
  List<AddonGroupModel> _availableAddonGroups = [];
  bool _loadingAddonGroups = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.existingItem?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.existingItem?.description ?? '');
    _priceController = TextEditingController(
      text: widget.existingItem?.price.toStringAsFixed(2) ?? '',
    );

    _isAvailable = widget.existingItem?.isAvailable ?? true;
    _isAddon = widget.existingItem?.isAddon ?? false;
    _addonGroupIds =
        List<String>.from(widget.existingItem?.addonGroupIds ?? []);

    _loadCategories();
    _loadAddonGroups();
  }

  Future<void> _loadCategories() async {
    final menuService = context.read<MenuService>();

    try {
      final categories = await menuService.getCategories(onlyActive: true);
      setState(() {
        _categories = categories;

        _selectedCategory = widget.existingItem != null
            ? categories.firstWhere(
                (c) => c.id == widget.existingItem!.categoryId,
                orElse: () => categories.first)
            : widget.initialCategory ??
                (categories.isNotEmpty ? categories.first : null);

        _loadingCategories = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadAddonGroups() async {
    final restaurantId = context.read<RestaurantScope>().restaurantId;
    final addonService = AddonService(restaurantId: restaurantId);

    try {
      final groups = await addonService.getAddonGroupsForAdmin();
      setState(() {
        _availableAddonGroups = groups;
        _loadingAddonGroups = false;
      });
    } catch (e) {
      debugPrint('Error loading addon groups: $e');
      setState(() => _loadingAddonGroups = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null) setState(() => _pickedImage = picked);
    } catch (e) {
      debugPrint('Failed to pick image: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final menuService = context.read<MenuService>();
    final restaurantScope = context.read<RestaurantScope>();

    final price = double.tryParse(_priceController.text);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid price')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // ================= EDIT EXISTING =================
      if (widget.existingItem != null) {
        String imageUrl = widget.existingItem!.imageUrl;

        if (_pickedImage != null) {
          final newUrl = await menuService.uploadMenuItemImage(
            image: _pickedImage!,
            categoryId: _selectedCategory!.id,
            menuItemId: widget.existingItem!.id,
          );

          if (widget.existingItem!.imageUrl.isNotEmpty) {
            await menuService
                .deleteMenuItemImage(widget.existingItem!.imageUrl);
          }

          imageUrl = newUrl;
        }

        final updatedItem = widget.existingItem!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          price: price,
          isAvailable: _isAvailable,
          isAddon: _isAddon,
          addonGroupIds: _addonGroupIds,
          imageUrl: imageUrl,
          categoryId: _selectedCategory!.id,
        );

        await menuService.updateMenuItem(
          categoryId: _selectedCategory!.id,
          item: updatedItem,
        );
      }
      // ================= CREATE NEW =================
      else {
        if (_pickedImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add an image')),
          );
          setState(() => _isSubmitting = false);
          return;
        }

        final newItem = MenuItemModel(
          id: '',
          restaurantId: restaurantScope.restaurantId,
          categoryId: _selectedCategory!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          imageUrl: '',
          price: price,
          isAvailable: _isAvailable,
          isAddon: _isAddon,
          addonGroupIds: _addonGroupIds,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final docRef = await menuService.createMenuItem(
          categoryId: _selectedCategory!.id,
          item: newItem,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menu item created! Uploading image...'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }

        _uploadImageInBackground(
          menuService: menuService,
          categoryId: _selectedCategory!.id,
          menuItemId: docRef.id,
          newItem: newItem,
        );
      }

      if (mounted && widget.existingItem != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu item updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('🔴 Save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save menu item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _uploadImageInBackground({
    required MenuService menuService,
    required String categoryId,
    required String menuItemId,
    required MenuItemModel newItem,
  }) async {
    try {
      final imageUrl = await menuService.uploadMenuItemImage(
        image: _pickedImage!,
        categoryId: categoryId,
        menuItemId: menuItemId,
      );

      await menuService.updateMenuItem(
        categoryId: categoryId,
        item: newItem.copyWith(id: menuItemId, imageUrl: imageUrl),
      );
    } catch (uploadError) {
      debugPrint('🔴 Background upload failed: $uploadError');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MenuItemImage(
              imageUrl: widget.existingItem?.imageUrl,
              pickedImage: _pickedImage,
              onImageSelected: (img) => setState(() => _pickedImage = img),
              onRemoveImage: () => setState(() => _pickedImage = null),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory?.id,
              items: _categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  )
                  .toList(),
              onChanged: widget.existingItem != null
                  ? null
                  : (id) {
                      setState(() {
                        _selectedCategory =
                            _categories.firstWhere((c) => c.id == id);
                      });
                    },
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            SwitchListTile(
              title: const Text('Available'),
              value: _isAvailable,
              onChanged: (v) => setState(() => _isAvailable = v),
            ),
            SwitchListTile(
              title: const Text('Is Addon'),
              value: _isAddon,
              onChanged: (v) => setState(() => _isAddon = v),
            ),

            // ── ADDON GROUPS SELECTOR ──
            // Only show for regular menu items (not addon items themselves)
            if (!_isAddon) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _AddonGroupsSelector(
                availableGroups: _availableAddonGroups,
                selectedIds: _addonGroupIds,
                isLoading: _loadingAddonGroups,
                onChanged: (groupId, selected) {
                  setState(() {
                    if (selected) {
                      _addonGroupIds.add(groupId);
                    } else {
                      _addonGroupIds.remove(groupId);
                    }
                  });
                },
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Saving...'),
                        ],
                      )
                    : Text(
                        widget.existingItem != null ? 'Update' : 'Create Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────
// ADDON GROUPS SELECTOR WIDGET
// ─────────────────────────────────────────────

class _AddonGroupsSelector extends StatelessWidget {
  final List<AddonGroupModel> availableGroups;
  final List<String> selectedIds;
  final bool isLoading;
  final void Function(String groupId, bool selected) onChanged;

  const _AddonGroupsSelector({
    required this.availableGroups,
    required this.selectedIds,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tune, size: 18, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              'Addon Groups',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${selectedIds.length} selected)',
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (availableGroups.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: colors.onSurface.withOpacity(0.5)),
                const SizedBox(width: 8),
                Text(
                  'No addon groups yet. Create them in Addon Groups.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: colors.outline.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: availableGroups.asMap().entries.map((entry) {
                final index = entry.key;
                final group = entry.value;
                final isSelected = selectedIds.contains(group.id);
                final isLast = index == availableGroups.length - 1;

                return Container(
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: colors.outline.withOpacity(0.15),
                            ),
                          ),
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (val) => onChanged(group.id, val!),
                    activeColor: const Color(0xFF0F2A12),
                    checkColor: Colors.white,
                    title: Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${group.selectionType == AddonSelectionType.single ? 'Pick one' : 'Pick up to ${group.maxSelections}'}'
                      '${group.required ? ' · Required' : ' · Optional'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurface.withOpacity(0.5),
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
