import 'package:flutter/material.dart';

/// Header widget for addon group form
class AddonGroupFormHeader extends StatelessWidget {
  final bool isEditing;

  const AddonGroupFormHeader({
    super.key,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(Icons.extension, color: colors.primary, size: 28),
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

/// Toggle tile widget for addon group form
class AddonGroupToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AddonGroupToggleTile({
    super.key,
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
