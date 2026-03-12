import 'package:flutter/material.dart';
import 'package:foodfleet/components/my_textfield.dart';
import 'package:foodfleet/components/mybutton.dart';
import 'package:foodfleet/models/addon_group_model.dart';
import 'package:foodfleet/models/menu_item_model.dart';
import 'package:foodfleet/services/addon_service.dart';
import 'addon_group_form_widgets.dart';
import 'addon_items_selector.dart';

class AddonGroupForm extends StatefulWidget {
  final String restaurantId;
  final AddonGroupModel? existingGroup;
  final VoidCallback onSaved;

  const AddonGroupForm({
    super.key,
    required this.restaurantId,
    this.existingGroup,
    required this.onSaved,
  });

  @override
  State<AddonGroupForm> createState() => _AddonGroupFormState();
}

class _AddonGroupFormState extends State<AddonGroupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minController = TextEditingController(text: '0');
  final _maxController = TextEditingController(text: '1');

  late final AddonService _addonService;
  bool _isRequired = false;
  bool _allowMultiple = false;
  bool _isLoading = false;

  List<MenuItemModel> _availableAddonItems = [];
  List<String> _selectedAddonItemIds = [];

  @override
  void initState() {
    super.initState();
    _addonService = AddonService(restaurantId: widget.restaurantId);

    if (widget.existingGroup != null) {
      _nameController.text = widget.existingGroup!.name;
      _descriptionController.text = widget.existingGroup!.description ?? '';
      _isRequired = widget.existingGroup!.required;
      _allowMultiple =
          widget.existingGroup!.selectionType == AddonSelectionType.multiple;
      _minController.text = widget.existingGroup!.minSelections.toString();
      _maxController.text = widget.existingGroup!.maxSelections.toString();
      _selectedAddonItemIds = List.from(widget.existingGroup!.addonItemIds);
    }

    _loadAddonItems();
  }

  Future<void> _loadAddonItems() async {
    try {
      final items = await _addonService.getAllAddonItemsForAdmin();
      setState(() => _availableAddonItems = items);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading addon items: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? width * 0.25 : 16,
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
                AddonGroupFormHeader(isEditing: widget.existingGroup != null),
                const SizedBox(height: 24),
                MyTextField(
                  controller: _nameController,
                  hintText: 'Addon group name',
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
                MyTextField(
                  controller: _descriptionController,
                  hintText: 'Description (optional)',
                  labelText: 'Description',
                  obscureText: false,
                ),
                const SizedBox(height: 12),
                AddonGroupToggleTile(
                  title: 'Required',
                  subtitle: 'Customer must select at least one option',
                  value: _isRequired,
                  onChanged: (value) => setState(() => _isRequired = value),
                ),
                AddonGroupToggleTile(
                  title: 'Allow multiple selections',
                  subtitle: 'Customer can select more than one option',
                  value: _allowMultiple,
                  onChanged: (value) => setState(() => _allowMultiple = value),
                ),
                const SizedBox(height: 16),
                if (_allowMultiple)
                  Row(
                    children: [
                      Expanded(
                        child: MyTextField(
                          controller: _minController,
                          hintText: '0',
                          labelText: 'Min',
                          obscureText: false,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MyTextField(
                          controller: _maxController,
                          hintText: '1',
                          labelText: 'Max',
                          obscureText: false,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                AddonItemsSelector(
                  availableItems: _availableAddonItems,
                  selectedItemIds: _selectedAddonItemIds,
                  onSelectionChanged: (ids) {
                    setState(() => _selectedAddonItemIds = ids);
                  },
                ),
                const SizedBox(height: 24),
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
                          text: widget.existingGroup != null
                              ? 'Update Group'
                              : 'Create Group',
                          color: colors.onPrimary,
                          foregroundColor: colors.tertiary,
                          onPress: _saveAddonGroup,
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

  Future<void> _saveAddonGroup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAddonItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one addon item')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final minSelections = int.tryParse(_minController.text) ?? 0;
      final maxSelections = int.tryParse(_maxController.text) ?? 1;
      final now = DateTime.now();

      if (widget.existingGroup != null) {
        final updatedGroup = widget.existingGroup!.copyWith(
          name: name,
          description: description.isEmpty ? null : description,
          selectionType: _allowMultiple
              ? AddonSelectionType.multiple
              : AddonSelectionType.single,
          required: _isRequired,
          minSelections: minSelections,
          maxSelections: maxSelections,
          addonItemIds: _selectedAddonItemIds,
        );

        await _addonService.updateAddonGroup(updatedGroup);
      } else {
        final existingGroups = await _addonService.getAddonGroupsForAdmin();
        final nextPosition = existingGroups.isEmpty
            ? 0
            : existingGroups
                    .map((g) => g.position)
                    .reduce((a, b) => a > b ? a : b) +
                1;

        final newGroup = AddonGroupModel(
          id: '',
          restaurantId: widget.restaurantId,
          name: name,
          description: description.isEmpty ? null : description,
          selectionType: _allowMultiple
              ? AddonSelectionType.multiple
              : AddonSelectionType.single,
          required: _isRequired,
          minSelections: minSelections,
          maxSelections: maxSelections,
          addonItemIds: _selectedAddonItemIds,
          position: nextPosition,
          createdAt: now,
          updatedAt: now,
        );

        await _addonService.createAddonGroup(newGroup);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingGroup != null
                  ? 'Addon group updated'
                  : 'Addon group created',
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
