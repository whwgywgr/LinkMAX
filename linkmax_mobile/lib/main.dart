import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'backups_screen.dart';
import 'categories_screen.dart';
import 'favicon.dart';
import 'import_export.dart';
import 'link_sheet.dart';
import 'models.dart';
import 'store.dart';

const MethodChannel _shareChannel = MethodChannel('com.linkmax.app/share');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = LinkStore();
  await store.load();
  await store.autoBackup();
  for (final link in store.links) {
    FaviconCache.warm(store, link);
  }
  runApp(LinkMaxApp(store));
}

class LinkMaxApp extends StatelessWidget {
  final LinkStore store;
  const LinkMaxApp(this.store, {super.key});

  ThemeData _theme(bool dark) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B5CF6),
      brightness: dark ? Brightness.dark : Brightness.light,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: dark ? const Color(0xFF12161C) : const Color(0xFFF4F6F8),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? const Color(0xFF1B222B) : Colors.white,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(
          bottom: BorderSide(
            color: dark ? const Color(0xFF2C3540) : const Color(0xFFE5E9F0),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF1B222B) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: dark ? const Color(0xFF2C3540) : const Color(0xFFE5E9F0),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: dark ? const Color(0xFF2C3540) : const Color(0xFFE5E9F0),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => MaterialApp(
        title: 'LinkMAX',
        debugShowCheckedModeBanner: false,
        theme: _theme(false),
        darkTheme: _theme(true),
        themeMode: store.settings.darkMode ? ThemeMode.dark : ThemeMode.light,
        home: HomeScreen(store: store),
      ),
    );
  }
}

// ================= Home =================

class HomeScreen extends StatefulWidget {
  final LinkStore store;
  const HomeScreen({super.key, required this.store});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _cat = 'all';
  String _search = '';
  bool _searchVisible = false;
  final _searchController = TextEditingController();

  LinkStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    _shareChannel.setMethodCallHandler((call) async {
      if (call.method == 'onShareReceived') {
        _handleSharedText(call.arguments as String?);
      }
    });
    _shareChannel.invokeMethod<String>('getInitialShare').then((shared) {
      if (shared != null && shared.isNotEmpty) _handleSharedText(shared);
    }).catchError((_) {});
  }

  void _handleSharedText(String? text) {
    if (text == null || text.isEmpty) return;
    final url = extractUrl(text);
    if (url == null) {
      _snack('No link found in the shared text');
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      showLinkSheet(context, store, initialUrl: url);
    });
  }

  void _resetCatIfGone() {
    if (_cat != 'all' && _cat != 'none' && store.categoryById(_cat) == null) {
      _cat = 'all';
    }
  }

  Future<void> _openLink(LinkItem link) async {
    final url = normalizeUrl(link.url);
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      _snack('This link cannot be opened');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _snack('Could not open this link');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1800)));
  }

  Future<void> _copyUrl(LinkItem link) async {
    await Clipboard.setData(ClipboardData(text: normalizeUrl(link.url)));
    _snack('URL copied');
  }

  void _showLinkActions(LinkItem link) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  FaviconCache.iconFor(link, size: 34, radius: 9),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          link.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          displayUrl(link.url),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Theme.of(sheetCtx).hintColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open in Browser'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _openLink(link);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy URL'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _copyUrl(link);
              },
            ),
            ListTile(
              leading: Icon(link.pinned ? Icons.push_pin_outlined : Icons.push_pin),
              title: Text(link.pinned ? 'Unpin' : 'Pin to top'),
              onTap: () {
                Navigator.pop(sheetCtx);
                store.togglePin(link);
                _snack(link.pinned ? 'Removed from pinned' : 'Pinned to top');
              },
            ),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.only(bottom: 6),
              leading: const Icon(Icons.folder_open),
              title: const Text('Move to category'),
              children: [
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.block, size: 18),
                  title: const Text('Uncategorized'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    store.moveLink(link, null);
                    _snack('Moved to Uncategorized');
                  },
                ),
                for (final cat in store.categories)
                  ListTile(
                    dense: true,
                    leading: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: Color(cat.colorValue), shape: BoxShape.circle),
                    ),
                    title: Text(cat.name),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      store.moveLink(link, cat.id);
                      _snack('Moved to ${cat.name}');
                    },
                  ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(sheetCtx);
                showLinkSheet(context, store, existing: link);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(sheetCtx).colorScheme.error),
              title: Text('Delete',
                  style: TextStyle(color: Theme.of(sheetCtx).colorScheme.error)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _confirmDeleteLink(link);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteLink(LinkItem link) {
    showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Delete link?'),
        content: Text('"${link.name}" will be removed permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dlgCtx).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(dlgCtx);
              store.deleteLink(link);
              _snack('Link deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _resetCatIfGone();

    return Scaffold(
      appBar: AppBar(
        title: _searchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search links...',
                  border: InputBorder.none,
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _search = '';
                        _searchVisible = false;
                      });
                    },
                  ),
                ),
                onChanged: (v) => setState(() => _search = v),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset('assets/icon-32.png', width: 22, height: 22),
                  ),
                  const SizedBox(width: 8),
                  const Text('LinkMAX', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                ],
              ),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _searchVisible = true),
          ),
          PopupMenuButton<String>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort),
            onSelected: store.setSortMode,
            itemBuilder: (_) => [
              for (final e in const {
                'name': 'Name A→Z',
                'nameDesc': 'Name Z→A',
                'newest': 'Newest first',
                'oldest': 'Oldest first',
              }.entries)
                CheckedPopupMenuItem(
                  value: e.key,
                  checked: store.settings.sortMode == e.key,
                  child: Text(e.value),
                ),
            ],
          ),
          IconButton(
            tooltip: store.settings.view == 'grid' ? 'List view' : 'Grid view',
            icon: Icon(store.settings.view == 'grid' ? Icons.view_list_outlined : Icons.grid_view_outlined),
            onPressed: () => store.setView(store.settings.view == 'grid' ? 'list' : 'grid'),
          ),
          IconButton(
            tooltip: 'Toggle dark mode',
            icon: Icon(store.settings.darkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => store.setDarkMode(!store.settings.darkMode),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (v) async {
              if (v == 'categories') {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => CategoriesScreen(store: store)));
                setState(_resetCatIfGone);
              } else if (v == 'backups') {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => BackupsScreen(store: store)));
              } else if (v == 'import') {
                await runImportFlow(context, store);
              } else if (v == 'exportJson') {
                final res = await runExportJson(context, store);
                _snack(res);
              } else if (v == 'exportHtml') {
                final res = await runExportHtml(context, store);
                _snack(res);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'categories', child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.folder_open),
                title: Text('Manage categories'),
              )),
              PopupMenuItem(value: 'backups', child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.history),
                title: Text('Backups & restore'),
              )),
              PopupMenuItem(value: 'import', child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.download),
                title: Text('Import links'),
              )),
              PopupMenuItem(value: 'exportJson', child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.upload),
                title: Text('Export JSON'),
              )),
              PopupMenuItem(value: 'exportHtml', child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.upload),
                title: Text('Export HTML bookmarks'),
              )),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _categoryChips(),
          Expanded(child: _linkArea()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showLinkSheet(context, store),
        icon: const Icon(Icons.add),
        label: const Text('Add Link'),
      ),
    );
  }

  Widget _categoryChips() {
    final scheme = Theme.of(context).colorScheme;
    Widget chip(String key, Widget label, int count, {Color? dotColor}) {
      final active = _cat == key;
      return InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () => setState(() {
          _cat = key;
          _search = '';
          _searchVisible = false;
          _searchController.clear();
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? scheme.primary : scheme.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: active ? scheme.primary : (scheme.outline.withValues(alpha: 0.35)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
              ],
              label,
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: active ? scheme.onPrimary : Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    TextStyle chipText(bool active) => TextStyle(
          fontSize: 13,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip('all', Text('All Links', style: chipText(_cat == 'all')), store.links.length),
            const SizedBox(width: 8),
            for (final cat in store.categories) ...[
              chip(
                cat.id,
                Text(cat.name, style: chipText(_cat == cat.id)),
                store.countFor(cat.id),
                dotColor: Color(cat.colorValue),
              ),
              const SizedBox(width: 8),
            ],
            if (store.uncategorizedCount > 0)
              chip('none', Text('Uncategorized', style: chipText(_cat == 'none')), store.uncategorizedCount),
          ],
        ),
      ),
    );
  }

  Widget _linkArea() {
    final links = store.visible(
      categoryFilter: _cat,
      query: _search,
      sortMode: store.settings.sortMode,
    );

    if (links.isEmpty) {
      return _emptyState();
    }

    final isGrid = store.settings.view == 'grid';
    return RefreshIndicator(
      onRefresh: () async {
        for (final l in links) {
          FaviconCache.warm(store, l);
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      child: isGrid
          ? GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 118,
              ),
              itemCount: links.length,
              itemBuilder: (context, i) => LinkCard(
                link: links[i],
                onTap: () => _openLink(links[i]),
                onLongPress: () => _showLinkActions(links[i]),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              itemCount: links.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => LinkTile(
                store: store,
                link: links[i],
                onTap: () => _openLink(links[i]),
                onLongPress: () => _showLinkActions(links[i]),
              ),
            ),
    );
  }

  Widget _emptyState() {
    final q = _search.trim();
    final String heading;
    final String sub;
    if (q.isNotEmpty) {
      heading = 'No results';
      sub = 'No links match "$q".';
    } else if (_cat == 'none') {
      heading = 'Nothing uncategorized';
      sub = 'Every link has a category. Nice and tidy.';
    } else if (store.links.isEmpty) {
      heading = 'No links yet';
      sub = 'Save your first link so you can open it anytime.';
    } else {
      heading = 'No links here';
      sub = 'Add a link to this category or pick another one.';
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.link, size: 30, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 14),
          Text(heading, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(sub, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13.5)),
        ],
      ),
    );
  }
}

// ================= Cards =================

class _CardShell extends StatelessWidget {
  final LinkItem link;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Widget child;
  const _CardShell({
    required this.link,
    required this.onTap,
    required this.onLongPress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? const Color(0xFF1B222B) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (link.pinned)
              Positioned(
                left: 0,
                top: 10,
                bottom: 10,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

class LinkCard extends StatelessWidget {
  final LinkItem link;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const LinkCard({
    super.key,
    required this.link,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      link: link,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaviconCache.iconFor(link, size: 34, radius: 9),
                const Spacer(),
                if (link.pinned)
                  Icon(Icons.push_pin, size: 14, color: Theme.of(context).colorScheme.primary),
              ],
            ),
            const Spacer(),
            Text(
              link.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
            const SizedBox(height: 2),
            Text(
              displayUrl(link.url),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

class LinkTile extends StatelessWidget {
  final LinkStore store;
  final LinkItem link;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const LinkTile({
    super.key,
    required this.store,
    required this.link,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cat = store.categoryOf(link);
    return _CardShell(
      link: link,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            FaviconCache.iconFor(link, size: 30, radius: 8),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  Text(
                    displayUrl(link.url),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                  ),
                ],
              ),
            ),
            if (cat != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: Color(cat.colorValue), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(cat.name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
            if (link.pinned) ...[
              const SizedBox(width: 8),
              Icon(Icons.push_pin, size: 14, color: Theme.of(context).colorScheme.primary),
            ],
          ],
        ),
      ),
    );
  }
}
