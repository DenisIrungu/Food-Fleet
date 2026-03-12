import 'package:flutter/material.dart';
import 'package:foodfleet/models/menu_item_model.dart';
import 'package:foodfleet/models/preview_display_item_model.dart';
import 'package:foodfleet/services/preview_service.dart';

class PreviewMenuScreen extends StatefulWidget {
  final String restaurantId;

  const PreviewMenuScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<PreviewMenuScreen> createState() => _PreviewMenuScreenState();
}

class _PreviewMenuScreenState extends State<PreviewMenuScreen> {
  final PreviewService _service = PreviewService();

  List<PreviewDisplayItemModel> _displayItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    final categories = await _service.fetchCategories(widget.restaurantId);

    final List<PreviewDisplayItemModel> items = [];

    for (final category in categories) {
      final menuItems = await _service.fetchMenuItemsByCategory(
          widget.restaurantId, category.id);

      if (menuItems.isEmpty) continue;

      items.add(PreviewCategoryHeaderModel(category.name));

      for (final item in menuItems) {
        items.add(PreviewMenuItemDisplayModel(item));
      }
    }

    setState(() {
      _displayItems = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "Preview Menu",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: _displayItems.length,
        itemBuilder: (context, index) {
          final item = _displayItems[index];

          if (item is PreviewCategoryHeaderModel) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 32, 18, 12),
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
            );
          }

          if (item is PreviewMenuItemDisplayModel) {
            return _buildMenuItemCard(item.item);
          }

          return const SizedBox();
        },
      ),
    );
  }

  // =========================================================
  // UPGRADED CARD
  // =========================================================
  Widget _buildMenuItemCard(MenuItemModel item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openAddons(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TEXT SECTION
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (item.description != null &&
                          item.description!.isNotEmpty)
                        Text(
                          item.description!,
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 14),
                      Text(
                        "KSh ${item.price.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // IMAGE
                if (item.imageUrl.isNotEmpty)
                  Hero(
                    tag: item.id,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        item.imageUrl,
                        width: 95,
                        height: 95,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // UPGRADED ADDON MODAL
  // =========================================================
  Future<void> _openAddons(MenuItemModel item) async {
    final groups = await _service.fetchAddonGroupsByIds(
        widget.restaurantId, item.addonGroupIds);

    final addonIds = groups.expand((g) => g.addonItemIds).toSet().toList();

    final addonItems =
        await _service.fetchAddonItemsByIds(widget.restaurantId, addonIds);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "KSh ${item.price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 24),
                for (final group in groups) ...[
                  Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...addonItems
                      .where((a) => group.addonItemIds.contains(a.id))
                      .map(
                        (addon) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.grey.shade100,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(addon.name),
                              Text(
                                "+ KSh ${addon.price.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
