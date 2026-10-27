import 'dart:convert';
import 'dart:typed_data';

import 'package:html/parser.dart' as html_parser;
import 'package:file_picker/file_picker.dart';

import 'models.dart';
import 'store.dart';

class IoResult {
  final bool ok;
  final String message;
  IoResult(this.ok, this.message);
}

// ---------- export ----------

String buildExportJson({
  required List<dynamic> categories,
  required List<dynamic> links,
}) {
  return const JsonEncoder.withIndent('  ').convert({
    'app': 'LinkMAX',
    'version': 1,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'categories': categories,
    'links': links,
  });
}

String escHtml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String buildNetscapeHtml({
  required List<MapEntry<String, List<MapEntry<String, String>>>> groups,
}) {
  final out = <String>[
    '<!DOCTYPE NETSCAPE-Bookmark-file-1>',
    '<!-- This is an automatically generated file. It will be read and overwritten. DO NOT EDIT! -->',
    '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">',
    '<TITLE>Bookmarks</TITLE>',
    '<H1>Bookmarks</H1>',
    '<DL><p>'
  ];
  for (final g in groups) {
    if (g.value.isEmpty) continue;
    out.add('    <DT><H3>${escHtml(g.key)}</H3>');
    out.add('    <DL><p>');
    for (final item in g.value) {
      out.add('        <DT><A HREF="${escHtml(item.key)}">${escHtml(item.value)}</A>');
    }
    out.add('    </DL><p>');
  }
  out.add('</DL><p>');
  return out.join('\n');
}

// ---------- import ----------

ImportPayload parseImportFile(String fileName, String content) {
  final trimmed = content.trim();
  final looksHtml =
      RegExp(r'\.html?$', caseSensitive: false).hasMatch(fileName) ||
          trimmed.startsWith('<');
  if (!looksHtml) {
    try {
      final parsed = _parseImportJson(jsonDecode(trimmed));
      if (parsed != null) return parsed;
    } catch (_) {}
  }
  final parsed = _parseBookmarksHtml(content);
  if (parsed != null) return parsed;
  throw const FormatException('Unrecognized file format');
}

ImportPayload? _parseImportJson(dynamic obj) {
  final cats = <String>[];
  final links = <ImportedLink>[];

  ImportedLink? pickLink(dynamic x) {
    if (x is! Map) return null;
    final url = normalizeUrl((x['url'] ?? x['href'] ?? '').toString());
    if (url.isEmpty || hostOf(url).isEmpty) return null;
    final name = (x['name'] ?? x['title'] ?? '').toString().trim();
    dynamic catRaw = x['categoryName'];
    if (catRaw == null && x['category'] is Map) catRaw = x['category']['name'];
    if (catRaw == null && x['category'] is String) catRaw = x['category'];
    final catName = catRaw?.toString().trim();
    return ImportedLink(name, url, (catName == null || catName.isEmpty) ? null : catName);
  }

  if (obj is List) {
    for (final x in obj) {
      final l = pickLink(x);
      if (l != null) links.add(l);
    }
  } else if (obj is Map) {
    final rawCats = (obj['categories'] as List?) ?? const [];
    for (final c in rawCats) {
      if (c is String && c.trim().isNotEmpty) {
        cats.add(c.trim());
      } else if (c is Map && (c['name'] ?? '').toString().trim().isNotEmpty) {
        cats.add(c['name'].toString().trim());
      }
    }
    final rawLinks = (obj['links'] as List?) ?? (obj['bookmarks'] as List?) ?? const [];
    for (final x in rawLinks) {
      final l = pickLink(x);
      if (l != null) links.add(l);
    }
  }
  if (links.isEmpty) return null;
  return ImportPayload(cats, links);
}

final _barNames =
    RegExp(r'^(bookmarks?[\s-]*(bar|menu|toolbar)|favorites?[\s-]*bar|other bookmarks)$',
        caseSensitive: false);

ImportPayload? _parseBookmarksHtml(String html) {
  final doc = html_parser.parse(html);
  final rootDls = doc.getElementsByTagName('dl');
  if (rootDls.isEmpty) return null;
  if (doc.getElementsByTagName('a').isEmpty) return null;

  final cats = <String>[];
  final seen = <String>{};
  final links = <ImportedLink>[];

  void walk(dynamic dl, String? ctxCategory) {
    for (final node in dl.children) {
      if (node.localName != 'dt') continue;
      final children = node.children;
      dynamic h3;
      dynamic anchor;
      dynamic subDl;
      for (final ch in children) {
        if (ch.localName == 'h3' && h3 == null) h3 = ch;
        if (ch.localName == 'a' && anchor == null) anchor = ch;
        if (ch.localName == 'dl' && subDl == null) subDl = ch;
      }
      if (h3 != null) {
        final name = h3.text.trim();
        var cat = ctxCategory;
        if (cat == null && name.isNotEmpty && !_barNames.hasMatch(name)) {
          cat = name;
          if (!seen.contains(name.toLowerCase())) {
            seen.add(name.toLowerCase());
            cats.add(name);
          }
        }
        if (subDl != null) walk(subDl, cat);
        continue;
      }
      if (anchor != null) {
        final href = (anchor.attributes['href'] ?? '').toString().trim();
        if (RegExp(r'^(https?|ftp):', caseSensitive: false).hasMatch(href)) {
          links.add(ImportedLink(
            anchor.text.trim(),
            href,
            ctxCategory,
          ));
        }
      }
    }
  }

  walk(rootDls.first, null);
  if (links.isEmpty) return null;
  return ImportPayload(cats, links);
}

// ---------- file pickers ----------

Future<(String?, Uint8List?)> pickImportFile() async {
  final res = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json', 'html', 'htm'],
  );
  final f = res.isEmpty ? null : res.single;
  if (f == null) return (null, null);
  final bytes = await f.readAsBytes();
  return (f.name, bytes);
}

Future<String?> saveExportFile({
  required String fileName,
  required String content,
}) async {
  final ext = fileName.split('.').last;
  final mime = ext == 'json' ? 'application/json' : 'text/html';
  final uri = await FilePicker.saveFile(
    fileName: fileName,
    bytes: Uint8List.fromList(utf8.encode(content)),
    mimeType: mime,
  );
  return uri?.toString();
}
