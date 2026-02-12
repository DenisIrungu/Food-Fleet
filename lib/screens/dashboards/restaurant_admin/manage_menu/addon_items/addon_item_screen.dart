import 'package:flutter/material.dart';
import 'package:foodfleet/components/addon_item_card.dart';
import 'package:foodfleet/models/menu_item_model.dart';
import 'package:foodfleet/services/addon_service.dart';
import 'addon_item_form.dart';

class AddonItemsScreen extends StatefulWidget {
  final String restaurantId;

  const AddonItemsScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<AddonItemsScreen> createState() => _AddonItemsScreenState();
}

class _AddonItemsScreenState extends State<AddonItemsScreen> {
  late final AddonService _addonService;

  @override
  void initState() {
    super.initState();
    _addonService = AddonService(restaurantId: widget.restaurantId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Addon Items'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Add Addon Item',
            icon: Icon(Icons.add, color: colors.onPrimary),
            onPressed: () => _openAddonItemForm(context),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: 16,
        ),
        child: FutureBuilder<List<MenuItemModel>>(
          future: _addonService.getAllAddonItemsForAdmin(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: colors.error),
                ),
              );
            }

            final addonItems = snapshot.data ?? [];

            if (addonItems.isEmpty) {
              return _EmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView.separated(
                itemCount: addonItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = addonItems[index];
                  return AddonItemCard(
                    item: item,
                    onEdit: () => _openAddonItemForm(context, item: item),
                    onDelete: () => _confirmDelete(context, item),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              onPressed: () => _openAddonItemForm(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  void _openAddonItemForm(BuildContext context, {MenuItemModel? item}) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (_) => AddonItemForm(
          restaurantId: widget.restaurantId,
          existingItem: item,
          onSaved: () {
            setState(() {}); // Refresh list
            Navigator.pop(context);
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddonItemForm(
            restaurantId: widget.restaurantId,
            existingItem: item,
            onSaved: () {
              setState(() {}); // Refresh list
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, MenuItemModel item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Addon Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAddonItem(item.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAddonItem(String itemId) async {
    try {
      await _addonService.deleteAddonItem(itemId);

      if (mounted) {
        setState(() {}); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Addon item deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// /* --------------------------------------------------------
//    Addon Item Card
// -------------------------------------------------------- */

// class _AddonItemCard extends StatelessWidget {
//   final MenuItemModel item;
//   final VoidCallback onEdit;
//   final VoidCallback onDelete;

//   const _AddonItemCard({
//     required this.item,
//     required this.onEdit,
//     required this.onDelete,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = Theme.of(context).colorScheme;

//     return Card(
//       color: colors.tertiary,
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         leading: item.imageUrl != null
//             ? ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: Image.network(
//                   item.imageUrl!,
//                   width: 50,
//                   height: 50,
//                   fit: BoxFit.cover,
//                   errorBuilder: (_, __, ___) => _PlaceholderImage(),
//                 ),
//               )
//             : _PlaceholderImage(),
//         title: Text(
//           item.name,
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             color: colors.onSurface,
//           ),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (item.description != null && item.description!.isNotEmpty)
//               Text(
//                 item.description!,
//                 style: TextStyle(color: colors.onSecondary, fontSize: 12),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             const SizedBox(height: 4),
//             Text(
//               '\KES ${item.price.toStringAsFixed(2)}',
//               style: TextStyle(
//                 color: colors.onPrimary,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             IconButton(
//               icon: Icon(Icons.edit, color: colors.onSecondary),
//               onPressed: onEdit,
//             ),
//             IconButton(
//               icon: const Icon(Icons.delete, color: Colors.redAccent),
//               onPressed: onDelete,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class _PlaceholderImage extends StatelessWidget {
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
      child: Icon(Icons.fastfood, color: colors.onSecondary),
    );
  }
}

/* --------------------------------------------------------
   Empty State
-------------------------------------------------------- */

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_shopping_cart, size: 64, color: colors.onSecondary),
          const SizedBox(height: 16),
          Text(
            'No addon items yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create addon items to add to your addon groups',
            style: TextStyle(color: colors.onSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
