import 'package:flutter/material.dart';
import 'package:foodfleet/components/addon_item_card.dart';
import 'package:foodfleet/models/addon_group_model.dart';
import 'package:foodfleet/models/menu_item_model.dart';
import 'package:foodfleet/services/addon_service.dart';

class AddonGroupDetailsScreen extends StatefulWidget {
  final String restaurantId;
  final AddonGroupModel group;

  const AddonGroupDetailsScreen({
    super.key,
    required this.restaurantId,
    required this.group,
  });

  @override
  State<AddonGroupDetailsScreen> createState() =>
      _AddonGroupDetailsScreenState();
}

class _AddonGroupDetailsScreenState extends State<AddonGroupDetailsScreen> {
  late final AddonService _addonService;

  String _searchQuery = '';

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
        title: Text(widget.group.name),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GroupInfoCard(group: widget.group),
            const SizedBox(height: 24),

            /// HEADER
            Text(
              'Addon Items (${widget.group.addonItemIds.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: 12),

            /// SEARCH FIELD
            TextField(
              decoration: InputDecoration(
                hintText: 'Search inside group...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colors.tertiary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),

            const SizedBox(height: 20),

            /// LIVE ITEMS
            Expanded(
              child: StreamBuilder<List<MenuItemModel>>(
                stream: _addonService
                    .streamAddonItemsByIds(widget.group.addonItemIds),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var items = snapshot.data!;

                  /// SEARCH FILTER
                  if (_searchQuery.isNotEmpty) {
                    items = items
                        .where((item) =>
                            item.name.toLowerCase().contains(_searchQuery))
                        .toList();
                  }

                  if (items.isEmpty) {
                    return const Center(
                      child: Text('No addon items found.'),
                    );
                  }

                  return ReorderableListView.builder(
                    itemCount: items.length,
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }

                      final updatedIds =
                          List<String>.from(widget.group.addonItemIds);

                      final movedItemId = updatedIds.removeAt(oldIndex);
                      updatedIds.insert(newIndex, movedItemId);

                      await _addonService.updateAddonGroupItemOrder(
                        groupId: widget.group.id,
                        newOrder: updatedIds,
                      );
                    },
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isUnavailable = !item.isAvailable;

                      return Opacity(
                        key: ValueKey(item.id),
                        opacity: isUnavailable ? 0.5 : 1,
                        child: Stack(
                          children: [
                            AddonItemCard(
                              item: item,
                              showActions: false,
                            ),

                            /// Quick availability toggle
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Switch(
                                value: item.isAvailable,
                                onChanged: (value) {
                                  _addonService.toggleAddonAvailability(
                                    addonItemId: item.id,
                                    isAvailable: value,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* --------------------------------------------------------
   GROUP INFO CARD
-------------------------------------------------------- */

class _GroupInfoCard extends StatelessWidget {
  final AddonGroupModel group;

  const _GroupInfoCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.tertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.description != null && group.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                group.description!,
                style: TextStyle(color: colors.onSecondary),
              ),
            ),

          /// ✅ FIXED: Using Wrap instead of Row (prevents overflow)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                text: group.required ? 'Required' : 'Optional',
              ),
              _InfoChip(
                text: group.selectionType == AddonSelectionType.multiple
                    ? 'Multiple'
                    : 'Single',
              ),
              if (group.selectionType == AddonSelectionType.multiple)
                _InfoChip(
                  text:
                      'Min ${group.minSelections} • Max ${group.maxSelections}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;

  const _InfoChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.onSecondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: colors.onSecondary,
        ),
      ),
    );
  }
}
