import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

import 'models.dart';
import 'store.dart';

/// Fetches and caches site favicons, mirroring the desktop app:
/// Google s2 → DuckDuckGo → origin/favicon.ico, stored by host hash.
class FaviconCache {
  static Directory? _dir;
  static final _inflight = <String, Future<String?>>{};
  static var _active = 0;

  static Future<Directory> _ensureDir() async {
    final d = _dir;
    if (d != null) return d;
    final support = await getApplicationSupportDirectory();
    final fav = Directory('${support.path}/favicons');
    if (!await fav.exists()) await fav.create(recursive: true);
    _dir = fav;
    return fav;
  }

  static Future<String?> fetchCached(String url) async {
    final host = hostOf(url);
    if (host.isEmpty) return null;
    final key = md5.convert(utf8.encode(host)).toString();
    final dir = await _ensureDir();
    final file = File('${dir.path}/$key.ico');
    if (await file.exists()) return file.path;
    if (_inflight.containsKey(url)) return _inflight[url];
    if (_active >= 6) return null; // retried on the next screen rebuild
    final task = _fetch(url, host, file).whenComplete(() {
      _inflight.remove(url);
      _active--;
    });
    _inflight[url] = task;
    _active++;
    return task;
  }

  static Future<String?> _fetch(String url, String host, File file) async {
    String? origin;
    try {
      origin = Uri.parse(url).origin;
    } catch (_) {}
    final candidates = <String>[
      'https://www.google.com/s2/favicons?sz=64&domain=${Uri.encodeComponent(host)}',
      'https://icons.duckduckgo.com/ip3/$host.ico',
      if (origin != null && origin.isNotEmpty) '$origin/favicon.ico',
    ];
    for (final c in candidates) {
      try {
        final res = await http.get(Uri.parse(c)).timeout(const Duration(seconds: 8));
        if (res.statusCode != 200) continue;
        final body = res.bodyBytes;
        if (body.length < 100) continue;
        final head = latin1.decode(body.sublist(0, body.length > 5 ? 5 : body.length));
        if (head.trimLeft().startsWith('<')) continue;
        await file.writeAsBytes(body);
        return file.path;
      } catch (_) {}
    }
    return null;
  }

  /// Kick off a background fetch for a link and update the store when done.
  static void warm(LinkStore store, LinkItem link) {
    if (link.favicon.isNotEmpty) return;
    fetchCached(link.url).then((path) {
      if (path != null) store.setFavicon(link, path);
    }).catchError((_) {});
  }

  /// Icon widget for a link: cached file → remote URL → letter avatar.
  static Widget iconFor(LinkItem link, {double size = 40, double radius = 10}) {
    final host = hostOf(link.url);
    final letterSource = link.name.trim().isNotEmpty ? link.name.trim() : host;
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(hashColor(host.isEmpty ? link.name : host)),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        letterSource.isEmpty ? '?' : letterSource.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
        ),
      ),
    );
    if (link.favicon.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(
          File(link.favicon),
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => placeholder,
        ),
      );
    }
    final remote = host.isEmpty
        ? null
        : 'https://www.google.com/s2/favicons?sz=64&domain=${Uri.encodeComponent(host)}';
    if (remote == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        remote,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}
