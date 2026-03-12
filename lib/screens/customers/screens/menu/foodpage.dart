import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodfleet/models/menu_item_model.dart';
import 'package:foodfleet/models/addon_group_model.dart';
import 'package:foodfleet/providers/cart_providers.dart';
import 'package:provider/provider.dart';

class FoodPage extends StatefulWidget {
  final MenuItemModel food;
  final String restaurantId;

  const FoodPage({
    super.key,
    required this.food,
    required this.restaurantId,
  });

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  int _quantity = 1;

  List<_AddonGroupWithItems> _addonGroups = [];
  bool _loadingAddons = true;

  final Map<String, Set<String>> _selections = {};

  @override
  void initState() {
    super.initState();
    _loadAddons();
  }

  Future<void> _loadAddons() async {
    if (widget.food.addonGroupIds.isEmpty) {
      setState(() => _loadingAddons = false);
      return;
    }

    try {
      final groupFutures = widget.food.addonGroupIds.map((groupId) async {
        final groupDoc = await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(widget.restaurantId)
            .collection('addon_groups')
            .doc(groupId)
            .get();

        if (!groupDoc.exists) return null;
        final group = AddonGroupModel.fromFirestore(groupDoc);

        final itemFutures = group.addonItemIds.map((itemId) async {
          final itemDoc = await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(widget.restaurantId)
              .collection('menu_items')
              .doc(itemId)
              .get();

          if (!itemDoc.exists) return null;
          return MenuItemModel.fromFirestore(itemDoc);
        });

        final items = (await Future.wait(itemFutures))
            .whereType<MenuItemModel>()
            .where((item) => item.isAddon && item.isAvailable)
            .toList();

        return _AddonGroupWithItems(group: group, items: items);
      });

      final results = (await Future.wait(groupFutures))
          .whereType<_AddonGroupWithItems>()
          .toList();

      results.sort((a, b) => a.group.position.compareTo(b.group.position));

      for (final g in results) {
        _selections[g.group.id] = {};
      }

      if (mounted) {
        setState(() {
          _addonGroups = results;
          _loadingAddons = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingAddons = false);
    }
  }

  double _calculateTotal() {
    double total = widget.food.price;

    for (final g in _addonGroups) {
      final selected = _selections[g.group.id] ?? {};
      for (final item in g.items) {
        if (selected.contains(item.id)) {
          total += item.price;
        }
      }
    }

    return total * _quantity;
  }

  bool _isValid() {
    for (final g in _addonGroups) {
      if (g.group.required) {
        final selected = _selections[g.group.id] ?? {};
        if (selected.length < g.group.minSelections) return false;
      }
    }
    return true;
  }

  void _addToCart() {
    final List<MenuItemModel> selectedAddonItems = [];
    for (final g in _addonGroups) {
      final selectedIds = _selections[g.group.id] ?? {};
      final items = g.items.where((item) => selectedIds.contains(item.id));
      selectedAddonItems.addAll(items);
    }

    context.read<CartProvider>().addToCart(
          restaurantId: widget.restaurantId,
          food: widget.food,
          selectedAddonItems: selectedAddonItems,
          quantity: _quantity,
        );

    // ✅ Snackbar BEFORE pop — context must still be valid
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.food.name} added to cart!'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0F2A12),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    Navigator.pop(context);
  }

  void _onSingleSelect(String groupId, String itemId) {
    setState(() {
      _selections[groupId] = {itemId};
    });
  }

  void _onMultiSelect(String groupId, String itemId, bool checked, int max) {
    setState(() {
      final current = _selections[groupId] ?? {};
      if (checked) {
        if (current.length < max) current.add(itemId);
      } else {
        current.remove(itemId);
      }
      _selections[groupId] = current;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroImage(imageUrl: widget.food.imageUrl),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.food.name,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      if (widget.food.description != null &&
                          widget.food.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.food.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurface.withOpacity(0.6),
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Ksh ${widget.food.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _QuantitySelector(
                        quantity: _quantity,
                        onDecrement: () {
                          if (_quantity > 1) setState(() => _quantity--);
                        },
                        onIncrement: () => setState(() => _quantity++),
                      ),
                      const SizedBox(height: 24),
                      if (_loadingAddons)
                        const _AddonsSkeleton()
                      else if (_addonGroups.isNotEmpty) ...[
                        Divider(color: cs.outline.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'Customise',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._addonGroups.map((g) => _AddonGroupWidget(
                              group: g,
                              selections: _selections[g.group.id] ?? {},
                              onSingleSelect: (itemId) =>
                                  _onSingleSelect(g.group.id, itemId),
                              onMultiSelect: (itemId, checked) =>
                                  _onMultiSelect(
                                g.group.id,
                                itemId,
                                checked,
                                g.group.maxSelections,
                              ),
                            )),
                      ],
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2A12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Ksh ${_calculateTotal().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isValid() ? _addToCart : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F2A12),
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isValid()
                                ? 'Add to Cart'
                                : 'Select required options',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isValid()
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── BACK BUTTON ──
          SafeArea(
            child: Container(
              margin: const EdgeInsets.only(left: 16, top: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_rounded),
                color: const Color(0xFF0F2A12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// INTERNAL DATA HOLDER
// ─────────────────────────────────────────────

class _AddonGroupWithItems {
  final AddonGroupModel group;
  final List<MenuItemModel> items;
  _AddonGroupWithItems({required this.group, required this.items});
}

// ─────────────────────────────────────────────
// HERO IMAGE
// ─────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final String imageUrl;
  const _HeroImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      clipBehavior: Clip.hardEdge,
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(color: Colors.grey.shade200);
              },
              errorBuilder: (_, __, ___) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.fastfood, size: 64, color: Colors.grey),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// QUANTITY SELECTOR
// ─────────────────────────────────────────────

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantitySelector({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Quantity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: onDecrement,
                icon: const Icon(Icons.remove_circle_outline),
                color: const Color(0xFF0F2A12),
                iconSize: 28,
                padding: EdgeInsets.zero,
                splashRadius: 20,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2A12).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2A12),
                  ),
                ),
              ),
              IconButton(
                onPressed: onIncrement,
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFF0F2A12),
                iconSize: 28,
                padding: EdgeInsets.zero,
                splashRadius: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ADDON GROUP WIDGET
// ─────────────────────────────────────────────

class _AddonGroupWidget extends StatelessWidget {
  final _AddonGroupWithItems group;
  final Set<String> selections;
  final void Function(String itemId) onSingleSelect;
  final void Function(String itemId, bool checked) onMultiSelect;

  const _AddonGroupWidget({
    required this.group,
    required this.selections,
    required this.onSingleSelect,
    required this.onMultiSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSingle = group.group.selectionType == AddonSelectionType.single;
    final isRequired = group.group.required;
    final max = group.group.maxSelections;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2A12).withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  group.group.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0F2A12),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRequired
                        ? const Color(0xFF0F2A12)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isRequired
                        ? 'Required'
                        : isSingle
                            ? 'Pick one'
                            : 'Pick up to $max',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isRequired ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...group.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = selections.contains(item.id);
            final isLast = index == group.items.length - 1;

            return Container(
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: cs.outline.withOpacity(0.15),
                        ),
                      ),
              ),
              child: isSingle
                  ? RadioListTile<String>(
                      value: item.id,
                      groupValue:
                          selections.isNotEmpty ? selections.first : null,
                      onChanged: (_) => onSingleSelect(item.id),
                      activeColor: const Color(0xFF0F2A12),
                      title: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '+ Ksh ${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade700,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    )
                  : CheckboxListTile(
                      value: isSelected,
                      onChanged: (val) => onMultiSelect(item.id, val!),
                      activeColor: const Color(0xFF0F2A12),
                      checkColor: Colors.white,
                      title: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '+ Ksh ${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade700,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ADDONS SKELETON
// ─────────────────────────────────────────────

class _AddonsSkeleton extends StatelessWidget {
  const _AddonsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.grey.shade200),
        const SizedBox(height: 16),
        _shimmer(width: 120, height: 20),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: List.generate(
              3,
              (i) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    _shimmer(width: 20, height: 20, radius: 4),
                    const SizedBox(width: 12),
                    _shimmer(width: 140, height: 14),
                    const Spacer(),
                    _shimmer(width: 60, height: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _shimmer(
      {required double width, required double height, double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
