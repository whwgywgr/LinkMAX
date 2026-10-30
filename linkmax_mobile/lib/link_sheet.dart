import 'package:flutter/material.dart';

import 'favicon.dart';
import 'models.dart';
import 'store.dart';

Future<void> showLinkSheet(
  BuildContext context,
  LinkStore store, {
  LinkItem? existing,
  String? initialUrl,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) =>
        _LinkSheet(store: store, existing: existing, initialUrl: initialUrl),
  );
}

class _LinkSheet extends StatefulWidget {
  final LinkStore store;
  final LinkItem? existing;
  final String? initialUrl;
  const _LinkSheet({required this.store, this.existing, this.initialUrl});

  @override
  State<_LinkSheet> createState() => _LinkSheetState();
}

class _LinkSheetState extends State<_LinkSheet> {
  late final TextEditingController _url;
  late final TextEditingController _name;
  String? _categoryId;
  LinkItem? _dup;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _url = TextEditingController(
        text: e?.url ?? normalizeUrl(widget.initialUrl ?? ''));
    _name = TextEditingController(text: e?.name ?? '');
    _categoryId = e?.categoryId;
    _checkDuplicate();
    _url.addListener(_checkDuplicate);
  }

  @override
  void dispose() {
    _url.dispose();
    _name.dispose();
    super.dispose();
  }

  void _checkDuplicate() {
    setState(() {
      _dup = _url.text.trim().isEmpty
          ? null
          : widget.store.findDuplicate(_url.text, excludeId: widget.existing?.id);
    });
  }

  void _save() {
    final url = normalizeUrl(_url.text);
    if (hostOf(url).isEmpty) {
      _snack('Enter a valid URL first');
      return;
    }
    var name = _name.text.trim();
    if (name.isEmpty) {
      name = deriveName(url).isNotEmpty ? deriveName(url) : hostOf(url);
    }
    if (widget.existing != null) {
      widget.store.updateLink(widget.existing!, name: name, url: url, categoryId: _categoryId);
      Navigator.pop(context);
      return;
    }
    final link = widget.store.addLink(name: name, url: url, categoryId: _categoryId);
    FaviconCache.warm(widget.store, link);
    Navigator.pop(context);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1800)));
  }

  @override
  Widget build(BuildContext context) {
    final hint = Theme.of(context).hintColor;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing != null ? 'Edit Link' : 'Add Link',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autofillHints: const [AutofillHints.url],
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://example.com',
            ),
          ),
          if (_dup != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                'Already saved${_dup!.name.isNotEmpty ? ' — "${_dup!.name}"' : ''}. Saving again will create a copy.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'My Link',
              helperText: 'Leave empty to use the website name',
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _categoryId,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Uncategorized')),
              for (final c in widget.store.categories)
                DropdownMenuItem(
                  value: c.id,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: Color(c.colorValue), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(c.name),
                    ],
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _save,
            icon: Icon(widget.existing != null ? Icons.check : Icons.add),
            label: Text(widget.existing != null ? 'Save Changes' : 'Add Link'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tip: paste a URL and the name fills itself from the website.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: hint),
          ),
        ],
      ),
    );
  }
}
