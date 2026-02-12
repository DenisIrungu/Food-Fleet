import 'package:flutter/material.dart';
import '../models/menu_item_model.dart';

class AddonItemCard extends StatelessWidget {
  final MenuItemModel item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// If false → hides edit/delete buttons
  final bool showActions;

  const AddonItemCard({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isAvailable = item.isAvailable;

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.6,
      child: Card(
        color: colors.tertiary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

          // IMAGE WITH FADE + BADGE
          leading: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _PlaceholderImage(),
                      )
                    : const _PlaceholderImage(),
              ),

              // Fade overlay when unavailable
              if (!isAvailable)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ],
          ),

          // TITLE + DESCRIPTION + PRICE
          title: Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
              if (!isAvailable)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Unavailable',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.error,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.description != null && item.description!.isNotEmpty)
                Text(
                  item.description!,
                  style: TextStyle(
                    color: colors.onSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Text(
                'KES ${item.price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          // ACTIONS (OPTIONAL)
          trailing: showActions
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: colors.onSecondary,
                        ),
                        onPressed: onEdit,
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.redAccent,
                        ),
                        onPressed: onDelete,
                      ),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: colors.onSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.fastfood,
        color: colors.onSecondary,
      ),
    );
  }
}
