import 'package:flutter/material.dart';
import 'addon_group_form.dart';

class AddonGroupsScreen extends StatelessWidget {
  const AddonGroupsScreen({super.key});

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
            onPressed: () {
              _openAddonForm(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: 16,
        ),
        child: const _AddonGroupList(),
      ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              onPressed: () {
                _openAddonForm(context);
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  void _openAddonForm(BuildContext context, {bool isEditing = false}) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (_) => AddonGroupForm(isEditing: isEditing),
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
          child: AddonGroupForm(isEditing: isEditing),
        ),
      );
    }
  }
}

/* --------------------------------------------------------
   STATIC LIST UI
-------------------------------------------------------- */

class _AddonGroupList extends StatelessWidget {
  const _AddonGroupList();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    /// Static mock data
    final addonGroups = List.generate(
      4,
      (index) => {
        'name': 'Addon Group ${index + 1}',
        'required': index % 2 == 0,
        'multiple': index % 3 == 0,
      },
    );

    if (addonGroups.isEmpty) {
      return _EmptyState();
    }

    return ListView.separated(
      itemCount: addonGroups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final group = addonGroups[index];

        return Card(
          color: colors.tertiary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              group['name'] as String,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            subtitle: Row(
              children: [
                _Chip(
                  text: group['required'] as bool ? 'Required' : 'Optional',
                  color: group['required'] as bool
                      ? colors.onPrimary
                      : colors.onSecondary,
                ),
                const SizedBox(width: 8),
                _Chip(
                  text: group['multiple'] as bool ? 'Multiple' : 'Single',
                  color: colors.onSecondary,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: colors.onSecondary),
                  onPressed: () {
                    _openEditForm(context);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    _confirmDelete(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openEditForm(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (_) => const AddonGroupForm(isEditing: true),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddonGroupForm(isEditing: true),
      );
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Addon Group'),
        content: const Text(
          'Are you sure you want to delete this addon group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: delete logic
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/* --------------------------------------------------------
   UI HELPERS
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
            'Create addon groups to attach extras to menu items',
            style: TextStyle(color: colors.onSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
