import 'package:flutter/material.dart';
import 'package:foodfleet/components/my_textfield.dart';
import 'package:foodfleet/components/mybutton.dart';

class AddonGroupForm extends StatefulWidget {
  final bool isEditing;

  const AddonGroupForm({
    super.key,
    this.isEditing = false,
  });

  @override
  State<AddonGroupForm> createState() => _AddonGroupFormState();
}

class _AddonGroupFormState extends State<AddonGroupForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _minController = TextEditingController(text: '0');
  final _maxController = TextEditingController(text: '1');

  bool _isRequired = false;
  bool _allowMultiple = false;

  @override
  void dispose() {
    _nameController.dispose();
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
        horizontal: isDesktop ? width * 0.3 : 16,
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(isEditing: widget.isEditing),
                const SizedBox(height: 24),

                /// Group Name
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

                /// Toggles
                _ToggleTile(
                  title: 'Required',
                  subtitle: 'Customer must select at least one option',
                  value: _isRequired,
                  onChanged: (value) {
                    setState(() => _isRequired = value);
                  },
                ),

                _ToggleTile(
                  title: 'Allow multiple selections',
                  subtitle: 'Customer can select more than one option',
                  value: _allowMultiple,
                  onChanged: (value) {
                    setState(() => _allowMultiple = value);
                  },
                ),

                const SizedBox(height: 16),

                /// Min / Max
                Row(
                  children: [
                    Expanded(
                      child: MyTextField(
                        controller: _minController,
                        hintText: '0',
                        labelText: 'Min',
                        obscureText: false,
                        keyboardType: TextInputType.number,
                        enabled: _allowMultiple,
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
                        enabled: _allowMultiple,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                /// Actions
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
                        text:
                            widget.isEditing ? 'Update Group' : 'Create Group',
                        color: colors.onPrimary,
                        foregroundColor: colors.tertiary,
                        onPress: () {
                          if (_formKey.currentState!.validate()) {
                            // TODO: save addon group
                            Navigator.pop(context);
                          }
                        },
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
}

/* --------------------------------------------------------
   UI Components
-------------------------------------------------------- */

class _Header extends StatelessWidget {
  final bool isEditing;

  const _Header({required this.isEditing});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          Icons.extension,
          color: colors.primary,
          size: 28,
        ),
        const SizedBox(width: 12),
        Text(
          isEditing ? 'Edit Addon Group' : 'Create Addon Group',
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

class _ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: colors.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colors.onSecondary),
      ),
      activeColor: colors.onPrimary,
      value: value,
      onChanged: onChanged,
    );
  }
}
