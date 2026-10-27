class LinkCategory {
  String id;
  String name;
  int colorValue; // 0xFFRRGGBB
  final int createdAt;

  LinkCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
  });

  static int? _parseColor(dynamic v) {
    if (v is String && v.startsWith('#')) {
      return int.tryParse(v.replaceFirst('#', ''), radix: 16);
    }
    if (v is num) return v.toInt();
    return null;
  }

  factory LinkCategory.fromJson(Map<String, dynamic> j) => LinkCategory(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        colorValue: _parseColor(j['color']) ??
            _parseColor(j['colorValue']) ??
            0xFF2563EB,
        createdAt: ((j['createdAt'] as num?) ?? 0).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': '#${colorValue.toRadixString(16).padLeft(8, '0')}',
        'createdAt': createdAt,
      };
}

class LinkItem {
  String id;
  String name;
  String url;
  String? categoryId;
  String favicon; // cached file name inside the favicons dir, '' when none
  bool pinned;
  final int createdAt;

  LinkItem({
    required this.id,
    required this.name,
    required this.url,
    required this.categoryId,
    required this.favicon,
    required this.pinned,
    required this.createdAt,
  });

  factory LinkItem.fromJson(Map<String, dynamic> j) => LinkItem(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        url: (j['url'] as String?) ?? '',
        categoryId: j['categoryId'] as String?,
        favicon: (j['favicon'] as String?) ?? '',
        pinned: j['pinned'] == true,
        createdAt: ((j['createdAt'] as num?) ?? 0).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'categoryId': categoryId,
        'favicon': favicon,
        'createdAt': createdAt,
        'pinned': pinned,
      };
}

class AppSettings {
  bool darkMode;
  String view; // 'grid' | 'list'
  String sortMode; // 'name' | 'nameDesc' | 'newest' | 'oldest'

  AppSettings({
    required this.darkMode,
    required this.view,
    required this.sortMode,
  });

  factory AppSettings.defaults() =>
      AppSettings(darkMode: false, view: 'grid', sortMode: 'name');
}

class ImportedLink {
  final String name;
  final String url;
  final String? categoryName;
  ImportedLink(this.name, this.url, this.categoryName);
}

class ImportPayload {
  final List<String> categories;
  final List<ImportedLink> links;
  ImportPayload(this.categories, this.links);
}
