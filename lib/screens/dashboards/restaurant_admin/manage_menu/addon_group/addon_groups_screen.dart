import 'package:flutter/material.dart';
import 'package:foodfleet/models/addon_group_model.dart';
import 'package:foodfleet/screens/dashboards/restaurant_admin/manage_menu/addon_group/addon_group_details_screen.dart';
import 'package:foodfleet/screens/dashboards/restaurant_admin/manage_menu/addon_group/addon_group_form.dart';
import 'package:foodfleet/services/addon_service.dart';

class AddonGroupsScreen extends StatefulWidget {
  final String restaurantId;

  const AddonGroupsScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<AddonGroupsScreen> createState() => _AddonGroupsScreenState();
}

class _AddonGroupsScreenState extends State<AddonGroupsScreen> {
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
        title: const Text('Addon Groups'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Add Addon Group',
            icon: Icon(Icons.add, color: colors.onPrimary),
            onPressed: () => _openAddonForm(context),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: 16,
        ),
        child: FutureBuilder<List<AddonGroupModel>>(
          future: _addonService.getAddonGroupsForAdmin(),
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

            final addonGroups = snapshot.data ?? [];

            if (addonGroups.isEmpty) {
              return _EmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView.separated(
                itemCount: addonGroups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final group = addonGroups[index];
                  return _AddonGroupCard(
                    group: group,
                    onEdit: () => _openAddonForm(context, group: group),
                    onDelete: () => _confirmDelete(context, group),
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
              onPressed: () => _openAddonForm(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  void _openAddonForm(BuildContext context, {AddonGroupModel? group}) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    final form = AddonGroupForm(
      restaurantId: widget.restaurantId,
      existingGroup: group,
      onSaved: () {
        setState(() {}); // Refresh list
        Navigator.pop(context);
      },
    );

    if (isDesktop) {
      showDialog(context: context, builder: (_) => form);
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: form,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, AddonGroupModel group) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Addon Group'),
        content: Text('Are you sure you want to delete "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAddonGroup(group.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAddonGroup(String groupId) async {
    try {
      await _addonService.deleteAddonGroup(groupId);

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Addon group deleted')),
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

/* --------------------------------------------------------
   Addon Group Card
-------------------------------------------------------- */

class _AddonGroupCard extends StatelessWidget {
  final AddonGroupModel group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddonGroupCard({
    required this.group,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.tertiary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddonGroupDetailsScreen(
                restaurantId: group.restaurantId,
                group: group,
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          group.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.description != null && group.description!.isNotEmpty)
              Text(
                group.description!,
                style: TextStyle(color: colors.onSecondary, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip(
                  text: group.required ? 'Required' : 'Optional',
                  color: group.required ? colors.onPrimary : colors.onSecondary,
                ),
                _Chip(
                  text: group.selectionType == AddonSelectionType.multiple
                      ? 'Multiple'
                      : 'Single',
                  color: colors.onSecondary,
                ),
                _Chip(
                  text: '${group.addonItemIds.length} items',
                  color: colors.onSecondary,
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: colors.onSecondary),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

/* --------------------------------------------------------
   UI Helpers
-------------------------------------------------------- */

class _Chip extends StatelessWidget {
  final String text;
  final Color color;

  const _Chip({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.extension, size: 64, color: colors.onSecondary),
          const SizedBox(height: 16),
          Text(
            'No addon groups yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create addon groups to organize your addon items',
            style: TextStyle(color: colors.onSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
