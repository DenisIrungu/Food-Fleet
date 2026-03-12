import 'package:flutter/material.dart';

class MenuHeader extends StatelessWidget {
  const MenuHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Menu Management",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Manage your categories, items, and add-ons.",
          style: TextStyle(
            fontSize: 14,
            color: colors.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
