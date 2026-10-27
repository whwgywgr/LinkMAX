import 'package:flutter/material.dart';

import 'favicon.dart';
import 'io.dart';
import 'models.dart';
import 'store.dart';

String _dateStamp() {
  final d = DateTime.now();
  final p = (int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${p(d.month)}-${p(d.day)}';
}

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 2600)));
}

/// Pick a JSON/HTML file, parse it and ask Merge vs Replace.
Future<void> runImportFlow(BuildContext context, LinkStore store) async {
  final (name, bytes) = await pickImportFile();
  if (name == null || bytes == null) return;

  final ImportPayload parsed;
  try {
    parsed = parseImportFile(name, String.fromCharCodes(bytes));
  } catch (_) {
    _snack(context, 'Could not import this file. Use a JSON or bookmarks HTML file.');
    return;
  }

  var mode = 'merge';
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) => StatefulBuilder(
      builder: (sheetCtx, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Import Links', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Found ${parsed.links.length} link${parsed.links.length == 1 ? '' : 's'}'
                '${parsed.categories.isEmpty ? '' : ' and ${parsed.categories.length} categor${parsed.categories.length == 1 ? 'y' : 'ies'}'}'
                ' in "$name".',
                style: TextStyle(color: Theme.of(sheetCtx).hintColor, fontSize: 13.5),
              ),
              const SizedBox(height: 14),
              RadioListTile<String>(
                value: 'merge',
                groupValue: mode,
                onChanged: (v) => setSheetState(() => mode = v!),
                title: const Text('Merge', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Keep current links and add the new ones', style: TextStyle(fontSize: 12.5)),
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                value: 'replace',
                groupValue: mode,
                onChanged: (v) => setSheetState(() => mode = v!),
                title: const Text('Replace all', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Remove current links, then import', style: TextStyle(fontSize: 12.5)),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 10),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                onPressed: () => Navigator.pop(sheetCtx, true),
                child: const Text('Import'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  if (confirmed != true || !context.mounted) return;
  final added = store.applyImport(parsed, mode == 'replace');
  for (final l in store.links) {
    FaviconCache.warm(store, l);
  }
  _snack(context, 'Imported $added link${added == 1 ? '' : 's'}');
}

Future<String> runExportJson(BuildContext context, LinkStore store) async {
  if (store.links.isEmpty) return 'Nothing to export yet';
  final content = buildExportJson(
    categories: store.categories.map((c) => c.toJson()).toList(),
    links: store.links.map((l) {
      final j = l.toJson();
      j.remove('pinned');
      j.remove('favicon');
      return j;
    }).toList(),
  );
  final saved = await saveExportFile(
    fileName: 'linkmax-backup-${_dateStamp()}.json',
    content: content,
  );
  if (saved == null) return 'Export cancelled';
  return 'Exported JSON backup';
}

Future<String> runExportHtml(BuildContext context, LinkStore store) async {
  if (store.links.isEmpty) return 'Nothing to export yet';
  final groups = <MapEntry<String, List<MapEntry<String, String>>>>[];
  for (final cat in store.categories) {
    final items = store.links
        .where((l) => l.categoryId == cat.id)
        .map((l) => MapEntry(normalizeUrl(l.url), l.name))
        .toList();
    groups.add(MapEntry(cat.name, items));
  }
  groups.add(MapEntry(
    'Uncategorized',
    store.links
        .where((l) => store.categoryById(l.categoryId) == null)
        .map((l) => MapEntry(normalizeUrl(l.url), l.name))
        .toList(),
  ));
  final content = buildNetscapeHtml(groups: groups);
  final saved = await saveExportFile(
    fileName: 'linkmax-bookmarks-${_dateStamp()}.html',
    content: content,
  );
  if (saved == null) return 'Export cancelled';
  return 'Exported HTML bookmarks';
}
