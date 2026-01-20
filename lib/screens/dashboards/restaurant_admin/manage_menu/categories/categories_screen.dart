import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodfleet/models/category_model.dart';
import 'package:foodfleet/services/category_service.dart';
import 'category_form.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  void _openCategoryForm(
    BuildContext context, {
    CategoryModel? category,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final form = CategoryForm(
      isEdit: category != null,
      category: category,
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final categoryService = context.read<CategoryService>();

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: colors.primary,
        actions: [
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () => _openCategoryForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0F2A12),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              onPressed: () => _openCategoryForm(context),
              child: const Icon(Icons.add),
            ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: categoryService.watchCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return const _EmptyState();
          }

          return _CategoriesList(
            categories: categories,
            onReorder: categoryService.updateCategoryPositions,
            onEdit: (category) =>
                _openCategoryForm(context, category: category),
            onDelete: categoryService.deleteCategory,
          );
        },
      ),
    );
  }
}

// ======================================================
// CATEGORIES LIST (REORDERABLE + PERSISTENT)
// ======================================================
class _CategoriesList extends StatefulWidget {
  final List<CategoryModel> categories;
  final Function(List<CategoryModel>) onReorder;
  final Function(CategoryModel) onEdit;
  final Function(String) onDelete;

  const _CategoriesList({
    required this.categories,
    required this.onReorder,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CategoriesList> createState() => _CategoriesListState();
}

class _CategoriesListState extends State<_CategoriesList> {
  late List<CategoryModel> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.categories);
  }

  @override
  void didUpdateWidget(covariant _CategoriesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _items = List.from(widget.categories);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ReorderableListView.builder(
      itemCount: _items.length,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex--;

        setState(() {
          final item = _items.removeAt(oldIndex);
          _items.insert(newIndex, item);
        });

        // 🔥 Persist order to Firestore
        await widget.onReorder(_items);
      },
      itemBuilder: (context, index) {
        final category = _items[index];

        return Card(
          key: ValueKey(category.id),
          color: colors.tertiary,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.drag_indicator),
            title: Text(
              category.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.secondary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusChip(isActive: category.isActive),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => widget.onEdit(category),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => widget.onDelete(category.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ======================================================
// EMPTY STATE
// ======================================================
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 64, color: colors.onSecondary),
          const SizedBox(height: 16),
          Text(
            'No categories yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add categories to organize your menu',
            style: TextStyle(color: colors.onSecondary),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// STATUS CHIP
// ======================================================
class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? colors.onPrimary.withOpacity(0.15)
            : colors.onSecondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? colors.onPrimary : colors.onSecondary,
        ),
      ),
    );
  }
}
