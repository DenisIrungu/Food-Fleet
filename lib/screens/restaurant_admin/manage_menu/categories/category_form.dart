import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodfleet/components/my_textfield.dart';
import 'package:foodfleet/components/mybutton.dart';
import 'package:foodfleet/models/category_model.dart';
import 'package:foodfleet/services/category_service.dart';
import 'package:foodfleet/providers/restaurant_scope_provider.dart';

class CategoryForm extends StatefulWidget {
  final bool isEdit;
  final CategoryModel? category;

  const CategoryForm({
    super.key,
    this.isEdit = false,
    this.category,
  });

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isActive = true;
  bool _isSubmitting = false;

  /// Whether this is a protected default category
  bool get _isDefault => widget.category?.isDefault ?? false;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit && widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description ?? '';
      _isActive = widget.category!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final categoryService = context.read<CategoryService>();
    final restaurantId = context.read<RestaurantScope>().restaurantId;

    try {
      if (widget.isEdit && widget.category != null) {
        // UPDATE — name is protected for default categories
        await categoryService.updateCategory(
          widget.category!.copyWith(
            name: _isDefault
                ? widget.category!.name // 🔒 keep original name
                : _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            isActive: _isActive,
          ),
        );
      } else {
        // CREATE
        final now = DateTime.now();

        await categoryService.createCategory(
          CategoryModel(
            id: '',
            restaurantId: restaurantId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            position: 9999,
            isActive: _isActive,
            isDefault: false, // new categories are never default
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 400 : 16,
        vertical: 24,
      ),
      backgroundColor: colors.tertiary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Title
              Row(
                children: [
                  Text(
                    widget.isEdit ? 'Edit Category' : 'Add Category',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.secondary,
                    ),
                  ),
                  if (_isDefault) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline,
                              size: 12, color: Colors.amber.shade800),
                          const SizedBox(width: 4),
                          Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              /// 🔒 Name field — disabled for default categories
              if (_isDefault) ...[
                Text(
                  'Category Name',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline,
                          size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Text(
                        _nameController.text,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Default category names cannot be changed.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                MyTextField(
                  controller: _nameController,
                  labelText: 'Category Name',
                  hintText: 'e.g. Starters',
                  obscureText: false,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Category name is required'
                      : null,
                ),
              ],

              /// Description — always editable
              MyTextField(
                controller: _descriptionController,
                labelText: 'Description (optional)',
                hintText: 'Short description',
                obscureText: false,
                maxlength: 80,
              ),

              const SizedBox(height: 12),

              /// Active toggle — always editable
              Row(
                children: [
                  Switch(
                    value: _isActive,
                    activeColor: colors.onPrimary,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _isActive ? colors.onPrimary : colors.onSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: MyButton(
                      text: 'Cancel',
                      color: colors.surface,
                      foregroundColor: colors.onSurface,
                      onPress: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MyButton(
                      text: _isSubmitting
                          ? 'Saving...'
                          : widget.isEdit
                              ? 'Update'
                              : 'Create',
                      color: colors.onPrimary,
                      foregroundColor: colors.tertiary,
                      onPress: _isSubmitting ? null : _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
