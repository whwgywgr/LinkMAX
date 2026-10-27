import 'package:flutter/material.dart';

import 'models.dart';
import 'store.dart';

class CategoriesScreen extends StatelessWidget {
  final LinkStore store;
  const CategoriesScreen({super.key, required this.store});

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1800)));
  }

  void _addOrRename(BuildContext context, {LinkCategory? existing}) {
    final controller = TextEditingController(text: existing?.name ?? '');
    showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(existing != null ? 'Rename Category' : 'New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Development'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              final dup = store.categories.any((c) =>
                  c.name.toLowerCase() == name.toLowerCase() && c.id != existing?.id);
              if (dup) {
                _snack(context, 'A category with this name already exists');
                return;
              }
              if (existing != null) {
                store.renameCategory(existing, name);
              } else {
                store.addCategory(name);
              }
              Navigator.pop(dlgCtx);
            },
            child: Text(existing != null ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }

  void _delete(BuildContext context, LinkCategory cat) {
    final count = store.countFor(cat.id);
    showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          count > 0
              ? 'Links in "${cat.name}" ($count) will move to Uncategorized. The category will be deleted.'
              : 'The category "${cat.name}" will be deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dlgCtx).colorScheme.error,
            ),
            onPressed: () {
              store.deleteCategory(cat);
              Navigator.pop(dlgCtx);
              _snack(context, 'Category deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrRename(context),
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (store.categories.isEmpty) {
            return Center(
              child: Text(
                'No categories yet.\nTap "New Category" to create one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: store.categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final cat = store.categories[i];
              return Material(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).dividerTheme.color ?? Colors.transparent,
                    ),
                  ),
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: Color(cat.colorValue), shape: BoxShape.circle),
                  ),
                  title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${store.countFor(cat.id)}',
                        style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12.5),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 19),
                        tooltip: 'Rename',
                        onPressed: () => _addOrRename(context, existing: cat),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 19,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        tooltip: 'Delete',
                        onPressed: () => _delete(context, cat),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
