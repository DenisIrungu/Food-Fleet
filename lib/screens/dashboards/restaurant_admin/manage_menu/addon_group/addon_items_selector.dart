import 'package:flutter/material.dart';
import 'package:foodfleet/models/menu_item_model.dart';

/// Widget for selecting addon items to include in a group
class AddonItemsSelector extends StatelessWidget {
  final List<MenuItemModel> availableItems;
  final List<String> selectedItemIds;
  final ValueChanged<List<String>> onSelectionChanged;

  const AddonItemsSelector({
    super.key,
    required this.availableItems,
    required this.selectedItemIds,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Addon Items',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose which addon items belong to this group',
          style: TextStyle(
            fontSize: 12,
            color: colors.onSecondary,
          ),
        ),
        const SizedBox(height: 12),
        if (availableItems.isEmpty)
          _EmptyState(colors: colors)
        else
          _ItemsList(
            availableItems: availableItems,
            selectedItemIds: selectedItemIds,
            onSelectionChanged: onSelectionChanged,
            colors: colors,
          ),
      ],
    );
  }
}

/// Empty state when no addon items are available
class _EmptyState extends StatelessWidget {
  final ColorScheme colors;

  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.onSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colors.onSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No addon items available. Create addon items first.',
              style: TextStyle(color: colors.onSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// List of addon items with checkboxes
class _ItemsList extends StatelessWidget {
  final List<MenuItemModel> availableItems;
  final List<String> selectedItemIds;
  final ValueChanged<List<String>> onSelectionChanged;
  final ColorScheme colors;

  const _ItemsList({
    required this.availableItems,
    required this.selectedItemIds,
    required this.onSelectionChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        border: Border.all(color: colors.onSecondary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: availableItems.length,
        itemBuilder: (context, index) {
          final item = availableItems[index];
          final isSelected = selectedItemIds.contains(item.id);

          return CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              final newSelection = List<String>.from(selectedItemIds);
              if (value == true) {
                newSelection.add(item.id);
              } else {
                newSelection.remove(item.id);
              }
              onSelectionChanged(newSelection);
            },
            activeColor: colors.onPrimary,
            title: Text(
              item.name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
            subtitle: Text(
              '\$${item.price.toStringAsFixed(2)}',
              style: TextStyle(color: colors.onSecondary),
            ),
            secondary: item.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      item.imageUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.fastfood,
                        color: colors.onSecondary,
                      ),
                    ),
                  )
                : Icon(Icons.fastfood, color: colors.onSecondary),
          );
        },
      ),
    );
  }
}
