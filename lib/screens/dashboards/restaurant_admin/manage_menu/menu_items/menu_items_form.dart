import 'package:flutter/material.dart';
import 'package:foodfleet/models/category_model.dart';
import 'package:foodfleet/models/menu_item_model.dart';
import 'package:foodfleet/providers/restaurant_scope_provider.dart';
import 'package:foodfleet/services/menu_service.dart';
import 'package:provider/provider.dart';

class MenuItemForm extends StatefulWidget {
  final MenuItemModel? existingItem;

  const MenuItemForm({super.key, this.existingItem});

  @override
  State<MenuItemForm> createState() => _MenuItemFormState();
}

class _MenuItemFormState extends State<MenuItemForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;

  bool _isAvailable = true;
  bool _isAddon = false;
  List<String> _addonGroupIds = [];

  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingItem?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.existingItem?.description ?? '');
    _priceController = TextEditingController(
        text: widget.existingItem?.price.toStringAsFixed(2) ?? '');
    _imageUrlController =
        TextEditingController(text: widget.existingItem?.imageUrl ?? '');
    _isAvailable = widget.existingItem?.isAvailable ?? true;
    _isAddon = widget.existingItem?.isAddon ?? false;
    _addonGroupIds = widget.existingItem?.addonGroupIds ?? [];

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final menuService = context.read<MenuService>();
    try {
      final categories = await menuService.getCategories(onlyActive: true);
      setState(() {
        _categories = categories;
        if (widget.existingItem != null) {
          _selectedCategoryId = widget.existingItem!.categoryId;
        } else if (categories.isNotEmpty) {
          _selectedCategoryId = categories.first.id;
        }
        _loadingCategories = false;
      });
    } catch (e) {
      debugPrint('Failed to load categories: $e');
      setState(() => _loadingCategories = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final restaurantScope = context.read<RestaurantScope>();
    final menuService = context.read<MenuService>();

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
    final price = double.tryParse(_priceController.text);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price must be a valid number')),
      );
      return;
    }

    final imageUrl = _imageUrlController.text.trim();
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image URL is required')),
      );
      return;
    }

    try {
      if (widget.existingItem != null) {
        // UPDATE
        final updatedItem = widget.existingItem!.copyWith(
          name: name,
          description: description,
          price: price,
          categoryId: _selectedCategoryId!,
          isAvailable: _isAvailable,
          isAddon: _isAddon,
          addonGroupIds: _addonGroupIds,
          imageUrl: imageUrl,
        );
        await menuService.updateMenuItem(updatedItem);
      } else {
        // CREATE NEW
        final newItem = MenuItemModel(
          id: '', // Firestore auto-generates
          restaurantId: restaurantScope.restaurantId,
          categoryId: _selectedCategoryId!,
          name: name,
          description: description,
          imageUrl: imageUrl,
          price: price,
          isAvailable: _isAvailable,
          isAddon: _isAddon,
          addonGroupIds: _addonGroupIds,
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await menuService.createMenuItem(newItem);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error saving menu item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save menu item')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCategories) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Material(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.existingItem != null
                      ? 'Edit Menu Item'
                      : 'New Menu Item',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Menu item name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    hintText: 'e.g., 120.00',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Price is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'Enter image link',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.isEmpty
                      ? 'Image URL is required'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Available'),
                  value: _isAvailable,
                  onChanged: (val) => setState(() => _isAvailable = val),
                ),
                SwitchListTile(
                  title: const Text('Is Addon'),
                  value: _isAddon,
                  onChanged: (val) => setState(() => _isAddon = val),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(widget.existingItem != null ? 'Update' : 'Add'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
}
