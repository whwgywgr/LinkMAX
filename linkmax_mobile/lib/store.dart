import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';

class LinkStore extends ChangeNotifier {
  List<LinkCategory> categories = [];
  List<LinkItem> links = [];
  AppSettings settings = AppSettings.defaults();

  File? _dataFile;

  static const palette = [
    0xFF8B5CF6, 0xFFDB2777, 0xFFEA580C, 0xFF16A34A,
    0xFF0891B2, 0xFFCA8A04, 0xFFE11D48, 0xFF0D9488,
    0xFF6366F1, 0xFF2563EB,
  ];

  static const seedNames = {
    'cat_dev': 'Development',
    'cat_social': 'Social',
    'cat_tools': 'Tools',
  };

  Future<File> get dataFile async {
    if (_dataFile != null) return _dataFile!;
    final dir = await getApplicationSupportDirectory();
    _dataFile = File('${dir.path}/linkmax-data.json');
    return _dataFile!;
  }

  Future<void> load() async {
    try {
      final file = await dataFile;
      final raw = await file.readAsString();
      _adopt(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _seed();
      await _persist();
    }
    notifyListeners();
  }

  void _adopt(Map<String, dynamic> data) {
    final cats = (data['categories'] as List?) ?? [];
    final lnks = (data['links'] as List?) ?? [];
    final s = (data['settings'] as Map?) ?? {};
    categories = cats
        .whereType<Map>()
        .map((c) => LinkCategory.fromJson(Map<String, dynamic>.from(c)))
        .where((c) => c.id.isNotEmpty && c.name.isNotEmpty)
        .toList();
    links = lnks
        .whereType<Map>()
        .map((l) => LinkItem.fromJson(Map<String, dynamic>.from(l)))
        .where((l) => l.url.isNotEmpty)
        .toList();
    settings = AppSettings(
      darkMode: s['theme'] == 'dark',
      view: s['view'] == 'list' ? 'list' : 'grid',
      sortMode: ['name', 'nameDesc', 'newest', 'oldest'].contains(s['sortMode'])
          ? s['sortMode'] as String
          : 'name',
    );
  }

  void _seed() {
    final now = DateTime.now().millisecondsSinceEpoch;
    var i = 0;
    final seedCats = {
      'cat_dev': 0xFF8B5CF6,
      'cat_social': 0xFFDB2777,
      'cat_tools': 0xFF16A34A,
    };
    categories = seedNames.entries
        .map((e) => LinkCategory(
              id: e.key,
              name: e.value,
              colorValue: seedCats[e.key]!,
              createdAt: now + (i++),
            ))
        .toList();
    LinkItem l(String name, String url, String cat) => LinkItem(
          id: 'lnk_${now + (i++)}',
          name: name,
          url: url,
          categoryId: cat,
          favicon: '',
          pinned: false,
          createdAt: now + (i++),
        );
    links = [
      l('GitHub', 'https://github.com', 'cat_dev'),
      l('Stack Overflow', 'https://stackoverflow.com', 'cat_dev'),
      l('MDN Web Docs', 'https://developer.mozilla.org', 'cat_dev'),
      l('ChatGPT', 'https://chatgpt.com', 'cat_tools'),
      l('npm', 'https://www.npmjs.com', 'cat_tools'),
      l('Google Drive', 'https://drive.google.com', 'cat_tools'),
      l('YouTube', 'https://www.youtube.com', 'cat_social'),
      l('X', 'https://x.com', 'cat_social'),
      l('Reddit', 'https://www.reddit.com', 'cat_social'),
    ];
    settings = AppSettings.defaults();
  }

  Future<void> _persist() async {
    try {
      final file = await dataFile;
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'version': 1,
          'settings': {
            'view': settings.view,
            'theme': settings.darkMode ? 'dark' : 'light',
            'sortMode': settings.sortMode,
          },
          'categories': categories.map((c) => c.toJson()).toList(),
          'links': links.map((l) => l.toJson()).toList(),
        }),
      );
    } catch (_) {}
  }

  // ---------- lookups ----------

  LinkCategory? categoryById(String? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  LinkCategory? categoryOf(LinkItem link) => categoryById(link.categoryId);

  LinkItem? findDuplicate(String url, {String? excludeId}) {
    final host = hostOf(url);
    if (host.isEmpty) return null;
    final key = normalizeUrl(url).toLowerCase().replaceAll(RegExp(r'/+$'), '');
    for (final l in links) {
      if (l.id == excludeId) continue;
      final other =
          normalizeUrl(l.url).toLowerCase().replaceAll(RegExp(r'/+$'), '');
      if (other == key) return l;
    }
    return null;
  }

  int get uncategorizedCount => links
      .where((l) => categoryById(l.categoryId) == null)
      .length;

  List<LinkItem> visible({
    required String categoryFilter,
    required String query,
    required String sortMode,
  }) {
    var out = links.toList();
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      out = out
          .where((l) =>
              l.name.toLowerCase().contains(q) ||
              l.url.toLowerCase().contains(q) ||
              hostOf(l.url).contains(q))
          .toList();
    } else if (categoryFilter == 'none') {
      out = out.where((l) => categoryById(l.categoryId) == null).toList();
    } else if (categoryFilter != 'all') {
      out = out.where((l) => l.categoryId == categoryFilter).toList();
    }
    int byName(LinkItem a, LinkItem b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());
    out.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      switch (sortMode) {
        case 'nameDesc':
          return byName(b, a);
        case 'newest':
          return b.createdAt.compareTo(a.createdAt);
        case 'oldest':
          return a.createdAt.compareTo(b.createdAt);
        default:
          return byName(a, b);
      }
    });
    return out;
  }

  int countFor(String? categoryId) {
    if (categoryId == null) return uncategorizedCount;
    return links.where((l) => l.categoryId == categoryId).length;
  }

  String nextColor() {
    final hex = palette[categories.length % palette.length];
    return '#${hex.toRadixString(16).padLeft(8, '0')}';
  }

  // ---------- mutations ----------

  void setDarkMode(bool value) {
    settings.darkMode = value;
    _persist();
    notifyListeners();
  }

  void setView(String view) {
    settings.view = view;
    _persist();
    notifyListeners();
  }

  void setSortMode(String mode) {
    settings.sortMode = mode;
    _persist();
    notifyListeners();
  }

  LinkItem addLink({
    required String name,
    required String url,
    String? categoryId,
  }) {
    final link = LinkItem(
      id: 'lnk_${DateTime.now().millisecondsSinceEpoch}_${links.length}',
      name: name,
      url: normalizeUrl(url),
      categoryId: categoryId,
      favicon: '',
      pinned: false,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    links.add(link);
    _persist();
    notifyListeners();
    return link;
  }

  void updateLink(LinkItem link, {required String name, required String url, String? categoryId}) {
    final urlChanged = link.url != normalizeUrl(url);
    link.name = name;
    link.url = normalizeUrl(url);
    link.categoryId = categoryId;
    if (urlChanged) link.favicon = '';
    _persist();
    notifyListeners();
  }

  void deleteLink(LinkItem link) {
    links.removeWhere((l) => l.id == link.id);
    _persist();
    notifyListeners();
  }

  void togglePin(LinkItem link) {
    link.pinned = !link.pinned;
    _persist();
    notifyListeners();
  }

  void moveLink(LinkItem link, String? categoryId) {
    if (link.categoryId == categoryId) return;
    link.categoryId = categoryId;
    _persist();
    notifyListeners();
  }

  void setFavicon(LinkItem link, String fileName) {
    link.favicon = fileName;
    _persist();
    notifyListeners();
  }

  LinkCategory addCategory(String name) {
    final cat = LinkCategory(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}_${categories.length}',
      name: name,
      colorValue: int.parse(nextColor().replaceFirst('#', ''), radix: 16),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    categories.add(cat);
    _persist();
    notifyListeners();
    return cat;
  }

  void renameCategory(LinkCategory cat, String name) {
    cat.name = name;
    _persist();
    notifyListeners();
  }

  void deleteCategory(LinkCategory cat) {
    for (final l in links) {
      if (l.categoryId == cat.id) l.categoryId = null;
    }
    categories.removeWhere((c) => c.id == cat.id);
    _persist();
    notifyListeners();
  }

  // ---------- backups ----------

  static const maxBackups = 5;

  Future<String> backupNow() async {
    final file = await dataFile;
    if (!await file.exists()) return 'Nothing to back up yet';
    final dir = await _backupDir();
    final stamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
    await file.copy('${dir.path}/linkmax-backup-$stamp.json');
    await _pruneBackups(dir);
    return 'Backup created';
  }

  /// Mirrors the desktop app: one automatic backup per day on launch.
  Future<void> autoBackup() async {
    try {
      final dir = await _backupDir();
      final marker = File('${dir.path}/.last-auto-backup');
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (await marker.exists() &&
          (await marker.readAsString()).trim() == today) {
        return;
      }
      final msg = await backupNow();
      if (msg == 'Backup created') await marker.writeAsString(today);
    } catch (_) {}
  }

  Future<void> _pruneBackups(Directory dir) async {
    final backups = (await dir.list().toList())
        .whereType<File>()
        .where((f) => f.uri.pathSegments.last.startsWith('linkmax-backup-'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    while (backups.length > maxBackups) {
      try {
        await backups.first.delete();
      } catch (_) {}
      backups.removeAt(0);
    }
  }

  Future<List<BackupInfo>> listBackups() async {
    try {
      final dir = await _backupDir();
      final out = <BackupInfo>[];
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (!name.startsWith('linkmax-backup-')) continue;
        final stat = await entity.stat();
        out.add(BackupInfo(name, stat.modified, stat.size));
      }
      out.sort((a, b) => b.modified.compareTo(a.modified));
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Restores a backup file, replacing current data. Returns error message or null.
  Future<String?> restoreBackup(String fileName) async {
    try {
      final dir = await _backupDir();
      final file = File('${dir.path}/$fileName');
      if (!await file.exists()) return 'Backup file not found';
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _adopt(data);
      await _persist();
      notifyListeners();
      return null;
    } catch (_) {
      return 'This backup could not be restored';
    }
  }

  Future<void> deleteBackup(String fileName) async {
    try {
      final dir = await _backupDir();
      final file = File('${dir.path}/$fileName');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  // ---------- import ----------

  /// Returns the number of links added.
  int applyImport(ImportPayload payload, bool replace) {
    if (replace) {
      categories = [];
      links = [];
    }
    final byName = <String, LinkCategory>{
      for (final c in categories) c.name.toLowerCase(): c
    };
    for (final c in payload.categories) {
      if (!byName.containsKey(c.toLowerCase())) {
        final cat = LinkCategory(
          id: 'cat_${DateTime.now().millisecondsSinceEpoch}_${categories.length}',
          name: c,
          colorValue: int.parse(nextColor().replaceFirst('#', ''), radix: 16),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        categories.add(cat);
        byName[c.toLowerCase()] = cat;
      }
    }
    final existing = <String>{
      for (final l in links)
        normalizeUrl(l.url).toLowerCase().replaceAll(RegExp(r'/+$'), '')
    };
    var added = 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final l in payload.links) {
      final url = normalizeUrl(l.url);
      final key = url.toLowerCase().replaceAll(RegExp(r'/+$'), '');
      if (hostOf(url).isEmpty || existing.contains(key)) continue;
      existing.add(key);
      LinkCategory? cat;
      if (l.categoryName != null) cat = byName[l.categoryName!.toLowerCase()];
      links.add(LinkItem(
        id: 'lnk_${now + added}',
        name: l.name.isNotEmpty ? l.name : (deriveName(url).isNotEmpty ? deriveName(url) : hostOf(url)),
        url: url,
        categoryId: cat?.id,
        favicon: '',
        pinned: false,
        createdAt: now + added,
      ));
      added++;
    }
    _persist();
    notifyListeners();
    return added;
  }
}

// ---------- URL helpers (same rules as the desktop app) ----------

/// Pulls the first URL out of arbitrary shared text (Share to LinkMAX).
String? extractUrl(String text) {
  if (text.isEmpty) return null;
  final http = RegExp("https?://[^\\s<>\"')\\]]+", caseSensitive: false)
      .firstMatch(text);
  if (http != null) return http.group(0);
  final www = RegExp(
          "(?:^|\\s)(www\\.[a-z0-9-]+(?:\\.[a-z0-9-]+)+[^\\s<>\"')\\]]*)",
          caseSensitive: false)
      .firstMatch(text);
  if (www != null) return 'https://${www.group(2)}';
  return null;
}

class BackupInfo {
  final String fileName;
  final DateTime modified;
  final int sizeBytes;
  BackupInfo(this.fileName, this.modified, this.sizeBytes);
}

Future<Directory> _backupDir() async {
  final support = await getApplicationSupportDirectory();
  final d = Directory('${support.path}/backups');
  if (!await d.exists()) await d.create(recursive: true);
  return d;
}

String normalizeUrl(String u) {
  final s = u.trim();
  if (s.isEmpty) return '';
  if (RegExp(r'^[a-z][a-z0-9+.-]*:', caseSensitive: false).hasMatch(s)) {
    return s;
  }
  return 'https://$s';
}

String hostOf(String u) {
  try {
    final uri = Uri.parse(normalizeUrl(u));
    final host = uri.host.replaceFirst(RegExp(r'^www\.'), '');
    if (host.isEmpty) return '';
    if (!RegExp(r'^[a-zA-Z0-9.-]+$').hasMatch(host)) return '';
    if (!host.contains('.') && host != 'localhost') return '';
    return host;
  } catch (_) {
    return '';
  }
}

String deriveName(String u) {
  final host = hostOf(u);
  if (host.isEmpty) return '';
  final core = host.split('.').first;
  if (core.isEmpty) return host;
  return core[0].toUpperCase() + core.substring(1);
}

String displayUrl(String u) {
  try {
    final uri = Uri.parse(normalizeUrl(u));
    final path = uri.path == '/' ? '' : uri.path;
    return '${uri.host.replaceFirst(RegExp(r'^www\.'), '')}$path'.replaceAll(RegExp(r'/+$'), '');
  } catch (_) {
    return u;
  }
}

int hashColor(String s) {
  var h = 7;
  for (var i = 0; i < s.length; i++) {
    h = ((h * 31) + s.codeUnitAt(i)) & 0x7fffffff;
  }
  return LinkStore.palette[h % LinkStore.palette.length];
}
